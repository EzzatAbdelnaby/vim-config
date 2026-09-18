-- Docs — read any documentation page inside Neovim instead of a browser.
-- Fetches the URL through Jina AI Reader (https://r.jina.ai), which renders
-- JS/SPA pages (NestJS, React docs, etc.) server-side and returns clean
-- markdown, written to a real file and opened in nvim (a new tab by default).
--
-- :Docs [url]     fetch a URL; with no arg uses the URL under the cursor,
--                 otherwise prompts for one.
-- <leader>kd      same as :Docs (cursor URL or prompt).
-- The page is saved under stdpath('cache')/docs and opened as a normal markdown
-- file (M.open_cmd controls how). `gx` on any link opens it in your browser.
--
-- Notes: the URL is sent to Jina's public reader (fine for public docs, not
-- for private/internal pages). Set M.api_key for higher rate limits, or point
-- M.reader at a self-hosted reader. Requires `curl` (already on macOS).

local M = {}

M.reader = "https://r.jina.ai/" -- reader prefix; final request is reader .. url
M.timeout = "45" -- curl --max-time seconds (Jina renders the page, can be slow)
M.api_key = nil -- optional Jina key -> sent as Bearer token for higher limits
M.open_cmd = "tabedit" -- how to open the doc file: tabedit | edit | vsplit | split
M.width = 0.45 -- split width fraction (only used when open_cmd == "vsplit")
M.prettify = true -- clean Jina output: real header, fenced+reflowed code, no anchors

-- Grab the first http(s) URL on the current line (so :Docs works on a link).
local function url_under_cursor()
  local line = vim.api.nvim_get_current_line()
  return line:match("https?://[%w%-._~:/?#%[%]@!$&'()*+,;=%%]+")
end

-- ── Markdown prettifier ────────────────────────────────────────────────────
-- Jina returns code as a single inline-backtick span with newlines collapsed.
-- We detect those, fence them, and reflow back onto indented lines.

local function guess_lang(code)
  if
    code:find("@%u")
    or code:find("import ")
    or code:find("export ")
    or code:find("=>")
    or code:find(":%s*number")
    or code:find(":%s*string")
    or code:find("const ")
  then
    return "ts"
  elseif code:find("npm ") or code:find("npx ") or code:find("yarn ") or code:find("^cd ") then
    return "bash"
  end
  return "text"
end

-- Re-indent by brace/paren depth so reflowed code reads like real code.
local function reindent(code)
  local out, depth = {}, 0
  for _, raw in ipairs(vim.split(code, "\n", { plain = true })) do
    local t = vim.trim(raw)
    if t ~= "" then
      local first = t:sub(1, 1)
      local opens = select(2, t:gsub("[%{%(%[]", ""))
      local closes = select(2, t:gsub("[%}%)%]]", ""))
      local indent = depth
      if first == "}" or first == ")" or first == "]" then
        indent = depth - 1
      end
      table.insert(out, string.rep("  ", math.max(0, indent)) .. t)
      depth = math.max(0, depth + opens - closes)
    end
  end
  return table.concat(out, "\n")
end

-- Reflow collapsed TS/JS by scanning char-by-char so we never insert a break
-- inside a string literal (the thing that mangled "Timber"/"Saw").
local REFLOW_KW = { "import ", "export ", "const ", "await ", "return ", "console." }

local function reflow_ts(code)
  local out, instr, i, n = {}, nil, 1, #code
  local stack = {} -- open-bracket stack: break after ',' only inside an object {}
  local function last()
    for k = #out, 1, -1 do
      if #out[k] > 0 then
        return out[k]:sub(-1)
      end
    end
    return ""
  end
  while i <= n do
    local c = code:sub(i, i)
    if instr then -- inside a string: copy verbatim, only watch for the closer
      if c == "\\" and i < n then
        out[#out + 1] = c .. code:sub(i + 1, i + 1)
        i = i + 2
      else
        out[#out + 1] = c
        if c == instr then
          instr = nil
          if code:sub(i + 1, i + 1):match("[%a_$]") then
            out[#out + 1] = "\n" -- "Saw"user -> break after the closing quote
          end
        end
        i = i + 1
      end
    elseif c == '"' or c == "'" or c == "`" then
      instr = c
      out[#out + 1] = c
      i = i + 1
    elseif c == "{" then
      stack[#stack + 1] = "{"
      out[#out + 1] = "{\n"
      i = i + 1
    elseif c == "}" then
      stack[#stack] = nil
      out[#out + 1] = "\n}"
      i = i + 1
    elseif c == "(" or c == "[" then
      stack[#stack + 1] = c
      out[#out + 1] = c
      i = i + 1
    elseif c == "]" then
      stack[#stack] = nil
      out[#out + 1] = "]"
      i = i + 1
    elseif c == ";" then
      out[#out + 1] = ";\n"
      i = i + 1
    elseif c == "," then
      out[#out + 1] = ","
      if stack[#stack] == "{" then
        out[#out + 1] = "\n" -- object property -> own line (arrays/args stay inline)
      end
      i = i + 1
    elseif c == "@" and code:sub(i + 1, i + 1):match("%u") then
      out[#out + 1] = "\n@"
      i = i + 1
    elseif c == ")" then
      stack[#stack] = nil
      out[#out + 1] = ")"
      if code:sub(i + 1, i + 1):match("[%a_$]") then
        out[#out + 1] = "\n" -- )user -> break (method chains use ). so are safe)
      end
      i = i + 1
    elseif (c == " " or c == "\t") and (last() == " " or last() == "") then
      i = i + 1 -- collapse runs of whitespace (we are outside any string here)
    else
      if last():match("[%w%)\"'`]") then
        for _, kw in ipairs(REFLOW_KW) do
          if code:sub(i, i + #kw - 1) == kw then
            out[#out + 1] = "\n" -- 25await / idconst -> break before the keyword
            break
          end
        end
      end
      out[#out + 1] = c
      i = i + 1
    end
  end
  return reindent(table.concat(out))
end

local function reflow_bash(code)
  local s = code
  for _, kw in ipairs({ "npm ", "npx ", "yarn ", "cd " }) do
    s = s:gsub("([%w%)\"'])%s*(" .. kw .. ")", "%1\n%2")
  end
  return vim.trim(s)
end

-- Rebuild an ASCII table whose rows were collapsed onto one line. Newlines
-- originally sat between a row-end and the next row: +|, |+, or ||.
local function reflow_table(code)
  local s = code:gsub("%+|", "+\n|"):gsub("|%+", "|\n+"):gsub("||", "|\n|")
  return s
end

-- Rebuild a box-drawing tree. Each line begins with │, ├ or └ glued to the
-- previous line's text. Those chars are UTF-8 \226\148 + {130=│, 156=├, 148=└};
-- break before one only when the previous char is real content (not a space or
-- another box char), which is exactly a line boundary.
local function reflow_tree(code)
  return (code:gsub("([%w%p])(\226\148[\130\156\148])", "%1\n%2"))
end

local function clean_markdown(content, url)
  local title = content:match("^Title:%s*(.-)\r?\n")
  local src = content:match("URL Source:%s*(.-)\r?\n") or url
  local body = content:gsub("^Title:.-Markdown Content:%s*\r?\n", "", 1)

  local out = {}
  if title and title ~= "" then
    table.insert(out, "# " .. title)
    table.insert(out, "")
  end
  table.insert(out, "> 🔗 Source: " .. src)
  table.insert(out, "")
  table.insert(out, "---")
  table.insert(out, "")

  for _, line in ipairs(vim.split(body, "\n", { plain = true })) do
    -- drop the "Direct link to ..." anchor dragged onto every heading
    line = line:gsub('%s*%[[^%]]*%]%([^%)]-"Direct link to[^"]-"%)', "")
    -- a line that is entirely one backtick span = a collapsed code block
    local code = line:match("^`(.-)`$")
    if code and (#code > 15 or code:find("[{};\n]")) then
      local lang, reflowed
      if code:find("%+%-%-") and code:find("|") then
        lang, reflowed = "text", reflow_table(code) -- ASCII table
      elseif code:find("\226\148") then
        lang, reflowed = "text", reflow_tree(code) -- box-drawing tree
      else
        lang = guess_lang(code)
        reflowed = (lang == "ts" and reflow_ts(code))
          or (lang == "bash" and reflow_bash(code))
          or code
      end
      table.insert(out, "```" .. lang)
      for _, cl in ipairs(vim.split(reflowed, "\n", { plain = true })) do
        table.insert(out, cl)
      end
      table.insert(out, "```")
    else
      table.insert(out, line)
    end
  end

  return (table.concat(out, "\n"):gsub("\n\n\n+", "\n\n"))
end

-- Turn a URL into a readable, filesystem-safe basename for the doc file.
local function slugify(url)
  local s = url:gsub("^https?://", ""):gsub("[^%w%-_.]+", "-")
  s = s:gsub("%-+", "-"):gsub("^%-+", ""):gsub("%-+$", "")
  if #s > 80 then
    s = s:sub(1, 80)
  end
  return s ~= "" and s or "page"
end

-- Write the fetched markdown to a real file and open it as a normal buffer.
function M.open_buffer(url, content)
  if M.prettify then
    content = clean_markdown(content, url)
  end
  local dir = vim.fn.stdpath("cache") .. "/docs"
  vim.fn.mkdir(dir, "p")
  local path = dir .. "/" .. slugify(url) .. ".md"

  local fd, err = io.open(path, "w")
  if not fd then
    vim.notify("Docs: could not write file — " .. (err or path), vim.log.levels.ERROR)
    return
  end
  fd:write(content)
  fd:close()

  vim.cmd(M.open_cmd .. " " .. vim.fn.fnameescape(path))
  local win = vim.api.nvim_get_current_win()
  if M.open_cmd == "vsplit" then
    vim.api.nvim_win_set_width(win, math.floor(vim.o.columns * M.width))
  end
  vim.wo[win].wrap = true
  vim.wo[win].linebreak = true
  vim.wo[win].conceallevel = 2
  vim.wo[win].spell = false
  vim.api.nvim_win_set_cursor(win, { 1, 0 })
end

-- Async fetch via Jina Reader; never blocks the editor.
function M.fetch(url)
  if not url:match("^https?://") then
    url = "https://" .. url
  end
  local cmd = { "curl", "-sL", "--max-time", M.timeout }
  if M.api_key then
    vim.list_extend(cmd, { "-H", "Authorization: Bearer " .. M.api_key })
  end
  table.insert(cmd, M.reader .. url)

  vim.notify("📖 Fetching " .. url .. " …", vim.log.levels.INFO)
  vim.system(cmd, { text = true }, vim.schedule_wrap(function(res)
    if res.code ~= 0 then
      vim.notify("Docs: fetch failed — " .. (res.stderr or "curl error"), vim.log.levels.ERROR)
      return
    end
    local out = res.stdout or ""
    if vim.trim(out) == "" then
      vim.notify("Docs: empty response (page may need a browser, or rate-limited)", vim.log.levels.WARN)
      return
    end
    M.open_buffer(url, out)
  end))
end

vim.api.nvim_create_user_command("Docs", function(opts)
  local arg = vim.trim(opts.args or "")
  if arg ~= "" then
    M.fetch(arg)
    return
  end
  local cursor_url = url_under_cursor()
  if cursor_url then
    M.fetch(cursor_url)
    return
  end
  vim.ui.input({ prompt = "Docs URL: " }, function(input)
    if input and vim.trim(input) ~= "" then
      M.fetch(vim.trim(input))
    end
  end)
end, { nargs = "?", desc = "Open a documentation URL as markdown in Neovim" })

vim.keymap.set("n", "<leader>kd", "<cmd>Docs<cr>", { desc = "Docs: open URL (cursor/prompt)" })

return M
