-- Confluence — Read and publish Confluence pages from Neovim
-- :Confluence [query]       search or show recent pages
-- :ConfluenceBrowse         browse spaces → pages
-- :ConfluencePublish        publish current buffer
-- :ConfluenceSetup          configure credentials

local M = {}

M.domain = nil
M.email = nil
M.token = nil
M._comments_ns = vim.api.nvim_create_namespace("confluence_comments")
M._inline_comments = {}
M._footer_comments = {}
M._comment_line_map = {}
M._style_ns = vim.api.nvim_create_namespace("confluence_style")

-- ── Highlights (rose-pine compatible) ──────────────────────
vim.api.nvim_set_hl(0, "ConfluenceH1", { default = true, bold = true, bg = "#26233a", fg = "#e0def4" })
vim.api.nvim_set_hl(0, "ConfluenceH2", { default = true, bold = true, bg = "#1f1d2e", fg = "#c4a7e7" })
vim.api.nvim_set_hl(0, "ConfluenceH3", { default = true, bold = true, fg = "#9ccfd8" })
vim.api.nvim_set_hl(0, "ConfluenceCode", { default = true, bg = "#1a1826" })
vim.api.nvim_set_hl(0, "ConfluenceCodeFence", { default = true, fg = "#6e6a86", bg = "#1a1826" })
vim.api.nvim_set_hl(0, "ConfluenceBlockquote", { default = true, bg = "#1f1d2e", italic = true })
vim.api.nvim_set_hl(0, "ConfluenceRule", { default = true, fg = "#6e6a86" })
vim.api.nvim_set_hl(0, "ConfluenceMeta", { default = true, fg = "#908caa", italic = true })
vim.api.nvim_set_hl(0, "ConfluenceBullet", { default = true, fg = "#c4a7e7", bold = true })
vim.api.nvim_set_hl(0, "ConfluenceLink", { default = true, fg = "#31748f", underline = true })
vim.api.nvim_set_hl(0, "ConfluenceTable", { default = true, bg = "#1f1d2e" })
vim.api.nvim_set_hl(0, "ConfluenceTableHeader", { default = true, bg = "#26233a", bold = true })
vim.api.nvim_set_hl(0, "ConfluenceTableSep", { default = true, fg = "#6e6a86" })
vim.api.nvim_set_hl(0, "ConfluenceDiagram", { default = true, bg = "#26233a", fg = "#f6c177" })
vim.api.nvim_set_hl(0, "ConfluenceDiagramBorder", { default = true, fg = "#6e6a86" })
vim.api.nvim_set_hl(0, "ConfluenceCodeLabel", { default = true, fg = "#908caa", bg = "#1a1826", italic = true })
vim.api.nvim_set_hl(0, "ConfluenceHeadingIcon", { default = true, fg = "#c4a7e7" })
vim.api.nvim_set_hl(0, "ConfluenceNumbered", { default = true, fg = "#c4a7e7", bold = true })

local function wrap_text(text, width)
  width = width or 80
  local out = {}
  for _, line in ipairs(vim.split(text, "\n")) do
    if #line <= width
      or line:match("^[#>|`]")
      or line:match("^%s*[%-%*%d]")
      or line:match("^%s*$")
      or line:match("^◈") then
      table.insert(out, line)
    else
      local cur = ""
      for word in line:gmatch("%S+") do
        if #cur + #word + 1 > width and cur ~= "" then
          table.insert(out, cur)
          cur = word
        else
          cur = cur == "" and word or (cur .. " " .. word)
        end
      end
      if cur ~= "" then table.insert(out, cur) end
    end
  end
  return table.concat(out, "\n")
end

local function url_encode(s)
  return s:gsub("([^%w%-%.%_%~])", function(c)
    return string.format("%%%02X", string.byte(c))
  end)
end

-- ── Config ──────────────────────────────────────────────────

function M._load_config()
  if M.domain and M.email and M.token then return true end

  M.domain = vim.env.CONFLUENCE_DOMAIN
  M.email = vim.env.CONFLUENCE_EMAIL
  M.token = vim.env.CONFLUENCE_TOKEN
  if M.domain and M.email and M.token then return true end

  local path = vim.fn.expand("~/.config/confluence/config.json")
  local f = io.open(path, "r")
  if f then
    local ok, cfg = pcall(vim.fn.json_decode, f:read("*a"))
    f:close()
    if ok and cfg then
      M.domain = M.domain or cfg.domain
      M.email = M.email or cfg.email
      M.token = M.token or cfg.token
    end
  end

  if M.domain and M.email and M.token then return true end
  vim.notify("Confluence not configured. Run :ConfluenceSetup", vim.log.levels.ERROR)
  return false
end

-- ── API ─────────────────────────────────────────────────────

function M._api(method, path, body)
  if not M._load_config() then return nil end

  local args = {
    "curl", "-s", "-S",
    "-w", "\n__HTTP__%{http_code}",
    "-u", M.email .. ":" .. M.token,
    "-H", "Content-Type: application/json",
    "-H", "Accept: application/json",
    "-X", method,
  }
  if body then
    table.insert(args, "-d")
    table.insert(args, body)
  end
  table.insert(args, "https://" .. M.domain .. path)

  local result = vim.system(args, { text = true }):wait()
  if result.code ~= 0 then
    vim.notify("Network error: " .. (result.stderr or ""), vim.log.levels.ERROR)
    return nil
  end

  local output = result.stdout or ""
  local status = tonumber(output:match("__HTTP__(%d+)%s*$")) or 0
  local resp = output:gsub("\n?__HTTP__%d+%s*$", "")

  if status == 401 then
    vim.notify("Auth failed — run :ConfluenceSetup", vim.log.levels.ERROR)
    M.domain, M.email, M.token = nil, nil, nil
    return nil
  elseif status == 403 then
    vim.notify("Permission denied", vim.log.levels.ERROR)
    return nil
  elseif status == 404 then
    vim.notify("Not found", vim.log.levels.ERROR)
    return nil
  elseif status < 200 or status >= 300 then
    vim.notify("API error (HTTP " .. status .. ")", vim.log.levels.ERROR)
    return nil
  end

  local ok, data = pcall(vim.fn.json_decode, resp)
  if not ok then
    vim.notify("Failed to parse response", vim.log.levels.ERROR)
    return nil
  end
  return data
end

-- ── Storage format → Markdown ───────────────────────────────

function M._storage_to_markdown(html)
  if not html or html == "" then return "" end
  local s = html

  -- 1. Extract code blocks (preserve whitespace inside them)
  local code_blocks = {}
  s = s:gsub('<ac:structured%-macro[^>]*ac:name="code"[^>]*>(.-)</ac:structured%-macro>', function(inner)
    local lang = inner:match('<ac:parameter[^>]*ac:name="language"[^>]*>([^<]*)</ac:parameter>') or ""
    local code = inner:match('<!%[CDATA%[(.-)%]%]>') or inner:match('<ac:plain%-text%-body>(.-)</ac:plain%-text%-body>') or ""
    local idx = #code_blocks + 1
    code_blocks[idx] = { lang = lang, code = code }
    return "\n\xC2\xA7CODE" .. idx .. "\xC2\xA7\n"
  end)

  -- 2. Info/note/warning panels → blockquotes
  s = s:gsub('<ac:structured%-macro[^>]*ac:name="(%w+)"[^>]*>.-<ac:rich%-text%-body>(.-)</ac:rich%-text%-body>.-</ac:structured%-macro>', function(name, body)
    body = body:gsub("<[^>]+>", ""):gsub("%s+", " "):gsub("^%s+", "")
    return "\n> **" .. name:upper() .. ":** " .. body .. "\n"
  end)

  -- 3. Images
  s = s:gsub('<ac:image[^>]*>.-<ri:url ri:value="([^"]*)"[^/]*/?>.-</ac:image>', '![image](%1)')
  s = s:gsub('<ac:image[^>]*>.-<ri:attachment ri:filename="([^"]*)"[^/]*/?>.-</ac:image>', '![%1](attachment:%1)')

  -- 3b. Diagrams (drawio, gliffy, lucidchart, plantuml, mermaid macro)
  for _, dname in ipairs({ "drawio", "gliffy", "lucidchart", "plantuml", "mermaid" }) do
    s = s:gsub('<ac:structured%-macro[^>]*ac:name="' .. dname .. '"[^>]*>.-</ac:structured%-macro>', function()
      local label = dname:sub(1, 1):upper() .. dname:sub(2)
      return "\n◈ " .. label .. " Diagram (open in browser to view)\n"
    end)
  end
  -- Table of contents macro
  s = s:gsub('<ac:structured%-macro[^>]*ac:name="toc"[^>]*>.-</ac:structured%-macro>', "\n◈ Table of Contents\n")
  s = s:gsub('<ac:structured%-macro[^>]*ac:name="toc"[^>]*/>', "\n◈ Table of Contents\n")

  -- 4. Strip remaining Confluence macros
  s = s:gsub('<ac:structured%-macro[^>]*>.-</ac:structured%-macro>', '')
  s = s:gsub('</?ac:[^>]*>', '')
  s = s:gsub('<ri:[^>]*/>', '')

  -- 5. Normalize whitespace (code block placeholders are safe)
  s = s:gsub("\r\n", " ")
  s = s:gsub("\n", " ")
  s = s:gsub("%s+", " ")

  -- 6. Tables
  s = s:gsub('<table[^>]*>(.-)</table>', function(tbl)
    return "\n" .. M._html_table_to_md(tbl) .. "\n"
  end)

  -- 7. Headings
  for i = 1, 6 do
    s = s:gsub('<h' .. i .. '[^>]*>(.-)</h' .. i .. '>', function(t)
      return "\n" .. string.rep("#", i) .. " " .. t:gsub("<[^>]+>", "") .. "\n"
    end)
  end

  -- 8. Lists
  s = s:gsub('<ul[^>]*>(.-)</ul>', function(list)
    local items = {}
    for item in list:gmatch('<li[^>]*>(.-)</li>') do
      item = item:gsub("<[^>]+>", ""):gsub("^%s+", ""):gsub("%s+$", "")
      table.insert(items, "- " .. item)
    end
    return "\n" .. table.concat(items, "\n") .. "\n"
  end)
  s = s:gsub('<ol[^>]*>(.-)</ol>', function(list)
    local items = {}
    local i = 0
    for item in list:gmatch('<li[^>]*>(.-)</li>') do
      i = i + 1
      item = item:gsub("<[^>]+>", ""):gsub("^%s+", ""):gsub("%s+$", "")
      table.insert(items, i .. ". " .. item)
    end
    return "\n" .. table.concat(items, "\n") .. "\n"
  end)

  -- 9. Inline formatting
  s = s:gsub('<strong[^>]*>(.-)</strong>', '**%1**')
  s = s:gsub('<b[^>]*>(.-)</b>', '**%1**')
  s = s:gsub('<em[^>]*>(.-)</em>', '*%1*')
  s = s:gsub('<i[^>]*>(.-)</i>', '*%1*')
  s = s:gsub('<code[^>]*>(.-)</code>', '`%1`')
  s = s:gsub('<a[^>]*href="([^"]*)"[^>]*>(.-)</a>', '[%2](%1)')

  -- 10. Block elements
  s = s:gsub('<p[^>]*>(.-)</p>', '%1\n\n')
  s = s:gsub('<br%s*/?>', '\n')
  s = s:gsub('<hr%s*/?>', '\n---\n')

  -- 11. Strip remaining tags
  s = s:gsub('<[^>]+>', '')

  -- 12. Decode entities
  s = s:gsub("&amp;", "&")
  s = s:gsub("&lt;", "<")
  s = s:gsub("&gt;", ">")
  s = s:gsub("&quot;", '"')
  s = s:gsub("&#39;", "'")
  s = s:gsub("&nbsp;", " ")
  s = s:gsub("&#(%d+);", function(n) return string.char(tonumber(n)) end)

  -- 13. Restore code blocks
  s = s:gsub("\xC2\xA7CODE(%d+)\xC2\xA7", function(idx)
    local b = code_blocks[tonumber(idx)]
    return b and ("\n```" .. b.lang .. "\n" .. b.code .. "\n```\n") or ""
  end)

  -- 14. Clean up
  s = s:gsub("\n\n\n+", "\n\n")
  s = s:gsub("^\n+", "")
  s = s:gsub("\n+$", "\n")

  -- 15. Wrap long paragraphs
  s = wrap_text(s, 80)

  return s
end

function M._html_table_to_md(tbl)
  local rows = {}
  for row_html in tbl:gmatch('<tr[^>]*>(.-)</tr>') do
    local cells = {}
    local is_header = false
    for tag, content in row_html:gmatch('<(t[hd])[^>]*>(.-)</t[hd]>') do
      if tag == "th" then is_header = true end
      content = content:gsub("<[^>]+>", ""):gsub("%s+", " "):gsub("^%s+", ""):gsub("%s+$", "")
      table.insert(cells, content)
    end
    if #cells > 0 then table.insert(rows, { cells = cells, header = is_header }) end
  end
  if #rows == 0 then return "" end

  local col_widths = {}
  for _, row in ipairs(rows) do
    for j, cell in ipairs(row.cells) do
      col_widths[j] = math.max(col_widths[j] or 3, #cell)
    end
  end

  local lines = {}
  for i, row in ipairs(rows) do
    local padded = {}
    for j, cell in ipairs(row.cells) do
      local w = col_widths[j] or #cell
      table.insert(padded, cell .. string.rep(" ", w - #cell))
    end
    table.insert(lines, "| " .. table.concat(padded, " | ") .. " |")
    if row.header or (i == 1 and #rows > 1) then
      local sep = {}
      for j = 1, #row.cells do
        table.insert(sep, string.rep("-", col_widths[j] or 3))
      end
      table.insert(lines, "| " .. table.concat(sep, " | ") .. " |")
    end
  end
  return table.concat(lines, "\n")
end

-- ── Markdown → Storage format ───────────────────────────────

function M._markdown_to_storage(md)
  local lines = vim.split(md, "\n")
  local html = {}
  local in_code = false
  local code_lang, code_lines = "", {}
  local in_list = false
  local list_tag = ""
  local in_table = false
  local table_rows = {}
  local para = {}

  local function flush_para()
    if #para > 0 then
      table.insert(html, "<p>" .. table.concat(para, " ") .. "</p>")
      para = {}
    end
  end

  local function flush_list()
    if in_list then
      table.insert(html, "</" .. list_tag .. ">")
      in_list = false
    end
  end

  local function flush_table()
    if #table_rows == 0 then return end
    local t = { "<table><tbody>" }
    for i, row in ipairs(table_rows) do
      table.insert(t, "<tr>")
      local tag = i == 1 and "th" or "td"
      for _, cell in ipairs(row) do
        table.insert(t, "<" .. tag .. ">" .. M._inline_md_to_html(cell) .. "</" .. tag .. ">")
      end
      table.insert(t, "</tr>")
    end
    table.insert(t, "</tbody></table>")
    table.insert(html, table.concat(t))
    table_rows = {}
    in_table = false
  end

  for _, line in ipairs(lines) do
    if line:match("^```") then
      if in_code then
        local code = table.concat(code_lines, "\n")
        local macro = '<ac:structured-macro ac:name="code">'
        if code_lang ~= "" then
          macro = macro .. '<ac:parameter ac:name="language">' .. code_lang .. '</ac:parameter>'
        end
        macro = macro .. '<ac:plain-text-body><![CDATA[' .. code .. ']]></ac:plain-text-body></ac:structured-macro>'
        table.insert(html, macro)
        in_code = false
        code_lines = {}
      else
        flush_para(); flush_list()
        if in_table then flush_table() end
        in_code = true
        code_lang = line:match("^```(%S*)") or ""
      end
    elseif in_code then
      table.insert(code_lines, line)
    elseif line:match("^#+%s") then
      flush_para(); flush_list()
      if in_table then flush_table() end
      local lvl = #line:match("^(#+)")
      local text = line:gsub("^#+%s+", "")
      table.insert(html, "<h" .. lvl .. ">" .. M._inline_md_to_html(text) .. "</h" .. lvl .. ">")
    elseif line:match("^[%-%*]%s") then
      flush_para()
      if in_table then flush_table() end
      if not in_list or list_tag ~= "ul" then
        flush_list()
        table.insert(html, "<ul>")
        in_list, list_tag = true, "ul"
      end
      table.insert(html, "<li>" .. M._inline_md_to_html(line:gsub("^[%-%*]%s+", "")) .. "</li>")
    elseif line:match("^%d+%.%s") then
      flush_para()
      if in_table then flush_table() end
      if not in_list or list_tag ~= "ol" then
        flush_list()
        table.insert(html, "<ol>")
        in_list, list_tag = true, "ol"
      end
      table.insert(html, "<li>" .. M._inline_md_to_html(line:gsub("^%d+%.%s+", "")) .. "</li>")
    elseif line:match("^|") then
      flush_para(); flush_list()
      in_table = true
      if not line:match("^|[%s%-|:]+$") then
        local cells = {}
        for cell in line:gmatch("|([^|]+)") do
          cell = cell:gsub("^%s+", ""):gsub("%s+$", "")
          if cell ~= "" then table.insert(cells, cell) end
        end
        if #cells > 0 then table.insert(table_rows, cells) end
      end
    elseif line:match("^>%s") then
      flush_para(); flush_list()
      if in_table then flush_table() end
      local text = line:gsub("^>%s*", "")
      table.insert(html, '<ac:structured-macro ac:name="info"><ac:rich-text-body><p>'
        .. M._inline_md_to_html(text) .. '</p></ac:rich-text-body></ac:structured-macro>')
    elseif line:match("^%-%-%-") or line:match("^%*%*%*") or line:match("^___") then
      flush_para(); flush_list()
      if in_table then flush_table() end
      table.insert(html, "<hr/>")
    elseif line == "" then
      flush_para(); flush_list()
      if in_table then flush_table() end
    else
      if in_table then flush_table() end
      flush_list()
      table.insert(para, M._inline_md_to_html(line))
    end
  end

  flush_para(); flush_list()
  if in_table then flush_table() end

  return table.concat(html, "\n")
end

function M._inline_md_to_html(text)
  text = text:gsub("&", "&amp;")
  text = text:gsub("<", "&lt;")
  text = text:gsub(">", "&gt;")
  text = text:gsub("%*%*(.-)%*%*", "<strong>%1</strong>")
  text = text:gsub("%*(.-)%*", "<em>%1</em>")
  text = text:gsub("`(.-)`", "<code>%1</code>")
  text = text:gsub("!%[(.-)%]%((.-)%)", '<ac:image><ri:url ri:value="%2"/></ac:image>')
  text = text:gsub("%[(.-)%]%((.-)%)", '<a href="%2">%1</a>')
  return text
end

-- ── Page comments ───────────────────────────────────────────

local function strip_md(text)
  text = text:gsub("%*%*(.-)%*%*", "%1")
  text = text:gsub("%*(.-)%*", "%1")
  text = text:gsub("`(.-)`", "%1")
  text = text:gsub("%[(.-)%]%(.-%)","% 1")
  text = text:gsub("^#+%s+", "")
  text = text:gsub("^[%-%*]%s+", "")
  text = text:gsub("^%d+%.%s+", "")
  text = text:gsub("^>%s+", "")
  return text
end

local function comment_author(c)
  if c.version and c.version.by then
    return c.version.by.displayName or c.version.by.publicName or "unknown"
  end
  return "unknown"
end

local function comment_time(c)
  if c.version and c.version.when then
    local y, mo, d, h, mi = c.version.when:match("(%d+)-(%d+)-(%d+)T(%d+):(%d+)")
    if y then return string.format("%s-%s-%s %s:%s", y, mo, d, h, mi) end
  end
  return ""
end

local function comment_body_text(c)
  if c.body and c.body.storage and c.body.storage.value then
    return c.body.storage.value:gsub("<[^>]+>", ""):gsub("&amp;", "&"):gsub("&lt;", "<"):gsub("&gt;", ">"):gsub("&nbsp;", " "):gsub("%s+", " "):gsub("^%s+", ""):gsub("%s+$", "")
  end
  return ""
end

function M._fetch_comments(page_id)
  local data = M._api("GET",
    "/wiki/rest/api/content/" .. page_id
    .. "/child/comment?expand=body.storage,extensions.inlineProperties,extensions.resolution,version,children.comment.body.storage,children.comment.version&depth=all&limit=100")
  if not data or not data.results then return end

  M._inline_comments = {}
  M._footer_comments = {}

  for _, c in ipairs(data.results) do
    local replies = {}
    if c.children and c.children.comment and c.children.comment.results then
      for _, r in ipairs(c.children.comment.results) do
        table.insert(replies, {
          id = r.id,
          author = comment_author(r),
          time = comment_time(r),
          body = comment_body_text(r),
        })
      end
    end

    local entry = {
      id = c.id,
      author = comment_author(c),
      time = comment_time(c),
      body = comment_body_text(c),
      resolved = c.extensions and c.extensions.resolution
        and c.extensions.resolution.status == "resolved",
      replies = replies,
    }

    if c.extensions and c.extensions.inlineProperties then
      entry.text_selection = c.extensions.inlineProperties.originalSelection or ""
      table.insert(M._inline_comments, entry)
    else
      table.insert(M._footer_comments, entry)
    end
  end
end

function M._render_comments(bufnr)
  vim.api.nvim_buf_clear_namespace(bufnr, M._comments_ns, 0, -1)
  M._comment_line_map = {}

  if #M._inline_comments == 0 then return end

  local buf_lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)

  for _, c in ipairs(M._inline_comments) do
    if c.text_selection and c.text_selection ~= "" then
      local sel = c.text_selection
      for i, line in ipairs(buf_lines) do
        local plain = strip_md(line)
        if plain:find(sel, 1, true) then
          M._comment_line_map[i] = M._comment_line_map[i] or {}
          table.insert(M._comment_line_map[i], c)

          local body = c.body:sub(1, 70)
          local count = #c.replies
          local suffix = count > 0 and (" (+" .. count .. " replies)") or ""
          local hl = c.resolved and "DiagnosticVirtualTextHint" or "DiagnosticVirtualTextInfo"
          local icon = c.resolved and " \xe2\x9c\x93 " or " \xe2\x97\x86 "

          vim.api.nvim_buf_set_extmark(bufnr, M._comments_ns, i - 1, 0, {
            virt_lines = { {
              { icon, hl },
              { "@" .. c.author .. ": ", "Special" },
              { body .. suffix, hl },
            } },
            virt_lines_above = false,
          })
          break
        end
      end
    end
  end
end

function M._add_inline_comment(bufnr, page_id)
  vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<Esc>", true, false, true), "x", false)
  vim.schedule(function()
    local sl = vim.fn.line("'<")
    local el = vim.fn.line("'>")
    local lines = vim.api.nvim_buf_get_lines(bufnr, sl - 1, el, false)
    local raw = table.concat(lines, " ")
    local selection = strip_md(raw):gsub("^%s+", ""):gsub("%s+$", "")

    if selection == "" then
      vim.notify("Select some text first", vim.log.levels.WARN)
      return
    end

    M._open_comment_input("Comment on: " .. selection:sub(1, 30), function(body)
      local payload = vim.fn.json_encode({
        type = "comment",
        container = { id = page_id, type = "page" },
        body = { storage = { value = "<p>" .. body:gsub("\n", "</p><p>") .. "</p>", representation = "storage" } },
        extensions = {
          inlineProperties = { originalSelection = selection },
        },
      })
      vim.notify("Posting comment...")
      local result = M._api("POST", "/wiki/rest/api/content", payload)
      if result then
        vim.notify("Comment posted")
        M._fetch_comments(page_id)
        M._render_comments(bufnr)
      end
    end)
  end)
end

function M._add_footer_comment(bufnr, page_id)
  M._open_comment_input("Page comment", function(body)
    local payload = vim.fn.json_encode({
      type = "comment",
      container = { id = page_id, type = "page" },
      body = { storage = { value = "<p>" .. body:gsub("\n", "</p><p>") .. "</p>", representation = "storage" } },
    })
    vim.notify("Posting comment...")
    local result = M._api("POST", "/wiki/rest/api/content", payload)
    if result then
      vim.notify("Comment posted")
      M._fetch_comments(page_id)
      M._render_comments(bufnr)
    end
  end)
end

function M._reply_to_comment(bufnr, page_id, comment)
  M._open_comment_input("Reply to @" .. comment.author, function(body)
    local payload = vim.fn.json_encode({
      type = "comment",
      container = { id = page_id, type = "page" },
      ancestors = { { id = comment.id } },
      body = { storage = { value = "<p>" .. body:gsub("\n", "</p><p>") .. "</p>", representation = "storage" } },
    })
    vim.notify("Posting reply...")
    local result = M._api("POST", "/wiki/rest/api/content", payload)
    if result then
      vim.notify("Reply posted")
      M._fetch_comments(page_id)
      M._render_comments(bufnr)
    end
  end)
end

function M._open_comment_input(title, on_submit)
  local buf = vim.api.nvim_create_buf(false, true)
  vim.bo[buf].filetype = "markdown"
  vim.bo[buf].bufhidden = "wipe"
  local w = math.min(70, vim.o.columns - 4)
  local h = 8
  local win = vim.api.nvim_open_win(buf, true, {
    relative = "editor",
    row = math.floor((vim.o.lines - h) / 2),
    col = math.floor((vim.o.columns - w) / 2),
    width = w, height = h,
    style = "minimal", border = "rounded",
    title = " " .. title .. " ", title_pos = "center",
    footer = " C-s submit  q cancel ", footer_pos = "center",
  })
  vim.wo[win].wrap = true
  vim.wo[win].linebreak = true
  vim.cmd("startinsert")

  local function close()
    if vim.api.nvim_win_is_valid(win) then vim.api.nvim_win_close(win, true) end
    vim.cmd("stopinsert")
  end

  vim.keymap.set({ "n", "i" }, "<C-s>", function()
    local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
    local body = vim.trim(table.concat(lines, "\n"))
    close()
    if body ~= "" and on_submit then on_submit(body) end
  end, { buffer = buf })
  vim.keymap.set("n", "q", close, { buffer = buf })
  vim.keymap.set("n", "<Esc>", close, { buffer = buf })
end

function M._view_comment_at_cursor(bufnr, page_id)
  local ln = vim.api.nvim_win_get_cursor(0)[1]
  local comments = M._comment_line_map[ln]
  if not comments or #comments == 0 then
    if #M._footer_comments > 0 then
      M._show_footer_comments(bufnr, page_id)
    else
      vim.notify("No comment at cursor", vim.log.levels.INFO)
    end
    return
  end
  M._show_comment_thread(bufnr, page_id, comments[1])
end

function M._show_comment_thread(bufnr, page_id, comment)
  local lines = {}
  local hls = {}

  local status = comment.resolved and "  RESOLVED" or ""
  table.insert(lines, " Thread" .. status)
  table.insert(hls, { #lines - 1, "Title" })
  table.insert(lines, " " .. string.rep("\xe2\x94\x80", 50))
  table.insert(hls, { #lines - 1, "NonText" })
  if comment.text_selection then
    table.insert(lines, "")
    table.insert(lines, ' "' .. comment.text_selection:sub(1, 60) .. '"')
    table.insert(hls, { #lines - 1, "String" })
  end
  table.insert(lines, "")

  local all = { { author = comment.author, time = comment.time, body = comment.body } }
  for _, r in ipairs(comment.replies or {}) do
    table.insert(all, r)
  end

  for i, c in ipairs(all) do
    table.insert(lines, " @" .. c.author .. "  " .. c.time)
    table.insert(hls, { #lines - 1, "Keyword" })
    for bl in c.body:gmatch("[^\n]*") do
      table.insert(lines, "  " .. bl)
    end
    if i < #all then
      table.insert(lines, "")
      table.insert(lines, " " .. string.rep("\xc2\xb7", 42))
      table.insert(hls, { #lines - 1, "NonText" })
      table.insert(lines, "")
    end
  end

  table.insert(lines, "")
  table.insert(lines, " " .. string.rep("\xe2\x94\x80", 50))
  table.insert(hls, { #lines - 1, "NonText" })
  table.insert(lines, " r reply   q close")

  local fbuf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_lines(fbuf, 0, -1, false, lines)
  vim.bo[fbuf].modifiable = false
  vim.bo[fbuf].filetype = "markdown"
  vim.bo[fbuf].bufhidden = "wipe"

  local ns = vim.api.nvim_create_namespace("confl_thread_hl")
  for _, h in ipairs(hls) do
    vim.api.nvim_buf_add_highlight(fbuf, ns, h[2], h[1], 0, -1)
  end

  local w = math.min(62, vim.o.columns - 4)
  local h = math.min(#lines, math.floor(vim.o.lines * 0.6))
  local win = vim.api.nvim_open_win(fbuf, true, {
    relative = "editor",
    row = math.floor((vim.o.lines - h) / 2),
    col = math.floor((vim.o.columns - w) / 2),
    width = w, height = h,
    style = "minimal", border = "rounded",
    title = " Comment Thread ", title_pos = "center",
  })
  vim.wo[win].wrap = true
  vim.wo[win].linebreak = true

  local function close()
    if vim.api.nvim_win_is_valid(win) then vim.api.nvim_win_close(win, true) end
  end
  vim.keymap.set("n", "q", close, { buffer = fbuf })
  vim.keymap.set("n", "<Esc>", close, { buffer = fbuf })
  vim.keymap.set("n", "r", function()
    close()
    M._reply_to_comment(bufnr, page_id, comment)
  end, { buffer = fbuf })
end

function M._show_footer_comments(bufnr, page_id)
  local lines = {}
  local hls = {}

  table.insert(lines, " Page Comments (" .. #M._footer_comments .. ")")
  table.insert(hls, { #lines - 1, "Title" })
  table.insert(lines, " " .. string.rep("\xe2\x94\x80", 50))
  table.insert(hls, { #lines - 1, "NonText" })
  table.insert(lines, "")

  for i, c in ipairs(M._footer_comments) do
    table.insert(lines, " @" .. c.author .. "  " .. c.time)
    table.insert(hls, { #lines - 1, "Keyword" })
    for bl in c.body:gmatch("[^\n]*") do
      table.insert(lines, "  " .. bl)
    end
    if i < #M._footer_comments then
      table.insert(lines, "")
      table.insert(lines, " " .. string.rep("\xc2\xb7", 42))
      table.insert(hls, { #lines - 1, "NonText" })
      table.insert(lines, "")
    end
  end

  table.insert(lines, "")
  table.insert(lines, " " .. string.rep("\xe2\x94\x80", 50))
  table.insert(hls, { #lines - 1, "NonText" })
  table.insert(lines, " q close")

  local fbuf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_lines(fbuf, 0, -1, false, lines)
  vim.bo[fbuf].modifiable = false
  vim.bo[fbuf].filetype = "markdown"
  vim.bo[fbuf].bufhidden = "wipe"

  local ns = vim.api.nvim_create_namespace("confl_footer_hl")
  for _, h in ipairs(hls) do
    vim.api.nvim_buf_add_highlight(fbuf, ns, h[2], h[1], 0, -1)
  end

  local w = math.min(62, vim.o.columns - 4)
  local ht = math.min(#lines, math.floor(vim.o.lines * 0.6))
  local win = vim.api.nvim_open_win(fbuf, true, {
    relative = "editor",
    row = math.floor((vim.o.lines - ht) / 2),
    col = math.floor((vim.o.columns - w) / 2),
    width = w, height = ht,
    style = "minimal", border = "rounded",
    title = " Page Comments ", title_pos = "center",
  })
  vim.wo[win].wrap = true
  vim.wo[win].linebreak = true

  local function close()
    if vim.api.nvim_win_is_valid(win) then vim.api.nvim_win_close(win, true) end
  end
  vim.keymap.set("n", "q", close, { buffer = fbuf })
  vim.keymap.set("n", "<Esc>", close, { buffer = fbuf })
end

function M._next_comment(dir)
  local cur = vim.api.nvim_win_get_cursor(0)[1]
  local sorted = {}
  for ln, _ in pairs(M._comment_line_map) do table.insert(sorted, ln) end
  table.sort(sorted)
  if #sorted == 0 then return end

  if dir > 0 then
    for _, ln in ipairs(sorted) do
      if ln > cur then vim.api.nvim_win_set_cursor(0, { ln, 0 }); return end
    end
    vim.api.nvim_win_set_cursor(0, { sorted[1], 0 })
  else
    for i = #sorted, 1, -1 do
      if sorted[i] < cur then vim.api.nvim_win_set_cursor(0, { sorted[i], 0 }); return end
    end
    vim.api.nvim_win_set_cursor(0, { sorted[#sorted], 0 })
  end
end

-- ── Page styling ───────────────────────────────────────────

function M._style_buffer(buf)
  local ns = M._style_ns
  vim.api.nvim_buf_clear_namespace(buf, ns, 0, -1)

  local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
  local in_code = false
  local code_lang = nil

  for i, line in ipairs(lines) do
    local ln = i - 1

    -- Code fences
    if line:match("^```") then
      if not in_code then
        code_lang = line:match("^```(%S+)")
        in_code = true
        vim.api.nvim_buf_add_highlight(buf, ns, "ConfluenceCodeFence", ln, 0, -1)
        if code_lang and code_lang ~= "" then
          local label = code_lang == "mermaid" and " mermaid diagram " or (" " .. code_lang .. " ")
          vim.api.nvim_buf_set_extmark(buf, ns, ln, 0, {
            virt_text = { { label, "ConfluenceCodeLabel" } },
            virt_text_pos = "right_align",
          })
        end
      else
        in_code = false
        code_lang = nil
        vim.api.nvim_buf_add_highlight(buf, ns, "ConfluenceCodeFence", ln, 0, -1)
      end
    elseif in_code then
      vim.api.nvim_buf_add_highlight(buf, ns, "ConfluenceCode", ln, 0, -1)

    -- Headings — overlay hides the # markers
    elseif line:match("^# ") then
      local text = line:match("^# (.+)")
      vim.api.nvim_buf_set_extmark(buf, ns, ln, 0, {
        virt_text = { { "◆ ", "ConfluenceHeadingIcon" }, { text, "ConfluenceH1" } },
        virt_text_pos = "overlay",
        line_hl_group = "ConfluenceH1",
      })
    elseif line:match("^## ") then
      local text = line:match("^## (.+)")
      vim.api.nvim_buf_set_extmark(buf, ns, ln, 0, {
        virt_text = { { "◇ ", "ConfluenceHeadingIcon" }, { text, "ConfluenceH2" } },
        virt_text_pos = "overlay",
        line_hl_group = "ConfluenceH2",
      })
    elseif line:match("^#### ") then
      local text = line:match("^#### (.+)")
      vim.api.nvim_buf_set_extmark(buf, ns, ln, 0, {
        virt_text = { { "  ▸ ", "ConfluenceHeadingIcon" }, { text, "ConfluenceH3" } },
        virt_text_pos = "overlay",
      })
    elseif line:match("^### ") then
      local text = line:match("^### (.+)")
      vim.api.nvim_buf_set_extmark(buf, ns, ln, 0, {
        virt_text = { { "▸ ", "ConfluenceHeadingIcon" }, { text, "ConfluenceH3" } },
        virt_text_pos = "overlay",
      })

    -- Horizontal rule
    elseif line:match("^%-%-%-") and line:match("^%-+$") then
      local width = math.max(60, vim.o.columns - 10)
      vim.api.nvim_buf_set_extmark(buf, ns, ln, 0, {
        virt_text = { { string.rep("─", width), "ConfluenceRule" } },
        virt_text_pos = "overlay",
      })

    -- Diagram placeholders
    elseif line:match("^◈ ") then
      local width = math.max(#line + 6, 44)
      local pad = width - #line - 4
      vim.api.nvim_buf_set_extmark(buf, ns, ln, 0, {
        virt_lines_above = true,
        virt_lines = { { { "  ┌" .. string.rep("─", width) .. "┐", "ConfluenceDiagramBorder" } } },
      })
      vim.api.nvim_buf_set_extmark(buf, ns, ln, 0, {
        virt_text = {
          { "  │  ", "ConfluenceDiagramBorder" },
          { line, "ConfluenceDiagram" },
          { string.rep(" ", pad), "ConfluenceDiagram" },
          { "  │", "ConfluenceDiagramBorder" },
        },
        virt_text_pos = "overlay",
      })
      vim.api.nvim_buf_set_extmark(buf, ns, ln, 0, {
        virt_lines = { { { "  └" .. string.rep("─", width) .. "┘", "ConfluenceDiagramBorder" } } },
      })

    -- Tables — handled in second pass below
    elseif line:match("^|.*|%s*$") then
      -- skip

    -- Metadata line (must check before generic blockquote)
    elseif line:match("^> %*%*Space:%*%*") then
      local space = line:match("Space:%*%* (%S+)") or "?"
      local ver = line:match("Version:%*%* (%d+)") or "?"
      vim.api.nvim_buf_set_extmark(buf, ns, ln, 0, {
        virt_text = {
          { "  Space: ", "ConfluenceMeta" },
          { space, "ConfluenceH3" },
          { "  │  Version: ", "ConfluenceMeta" },
          { ver, "ConfluenceH3" },
        },
        virt_text_pos = "overlay",
      })

    -- Blockquote
    elseif line:match("^> ") then
      vim.api.nvim_buf_add_highlight(buf, ns, "ConfluenceBlockquote", ln, 0, -1)

    -- Bullet points
    elseif line:match("^%s*[%-%*] ") then
      local s, e = line:find("[%-%*]")
      if s then
        vim.api.nvim_buf_add_highlight(buf, ns, "ConfluenceBullet", ln, s - 1, e)
      end

    -- Numbered list
    elseif line:match("^%s*%d+%. ") then
      local s, e = line:find("%d+%.")
      if s then
        vim.api.nvim_buf_add_highlight(buf, ns, "ConfluenceNumbered", ln, s - 1, e)
      end

    -- Regular text — inline styling
    else
      local pos = 1
      while true do
        local s, e = line:find("%[.-%]%(.-%)"), pos
        if not s then break end
        vim.api.nvim_buf_add_highlight(buf, ns, "ConfluenceLink", ln, s - 1, e)
        pos = e + 1
      end
    end
  end

  -- ── Table box-drawing (second pass) ──
  local ti = 1
  while ti <= #lines do
    if lines[ti]:match("^|.*|%s*$") then
      local block_start = ti
      local block_end = ti
      while block_end < #lines and lines[block_end + 1]:match("^|.*|%s*$") do
        block_end = block_end + 1
      end

      -- Parse column widths from all data rows
      local col_widths = {}
      for j = block_start, block_end do
        if not lines[j]:match("^|[%s%-:|]+|%s*$") then
          local col = 0
          for cell in lines[j]:gmatch("|([^|]+)") do
            col = col + 1
            col_widths[col] = math.max(col_widths[col] or 0, #cell)
          end
        end
      end
      if #col_widths == 0 then
        ti = block_end + 1
        goto continue
      end

      -- Build border strings
      local top_parts, mid_parts, bot_parts = {}, {}, {}
      for c = 1, #col_widths do
        local w = col_widths[c]
        table.insert(top_parts, string.rep("─", w))
        table.insert(mid_parts, string.rep("─", w))
        table.insert(bot_parts, string.rep("─", w))
      end
      local top_border = "┌" .. table.concat(top_parts, "┬") .. "┐"
      local mid_border = "├" .. table.concat(mid_parts, "┼") .. "┤"
      local bot_border = "└" .. table.concat(bot_parts, "┴") .. "┘"

      -- Top border above first row
      vim.api.nvim_buf_set_extmark(buf, ns, block_start - 1, 0, {
        virt_lines_above = true,
        virt_lines = { { { top_border, "ConfluenceTableSep" } } },
      })

      -- Process each row
      for j = block_start, block_end do
        local jln = j - 1
        local jline = lines[j]

        if jline:match("^|[%s%-:|]+|%s*$") then
          -- Separator → box mid-border
          vim.api.nvim_buf_set_extmark(buf, ns, jln, 0, {
            virt_text = { { mid_border, "ConfluenceTableSep" } },
            virt_text_pos = "overlay",
          })
        else
          -- Data/header row → replace | with │, multi-chunk for colors
          local is_header = j < block_end and lines[j + 1]:match("^|[%s%-:|]+|%s*$")
          local hl = is_header and "ConfluenceTableHeader" or "ConfluenceTable"
          local chunks = {}
          local cells = {}
          for cell in jline:gmatch("|([^|]+)") do
            table.insert(cells, cell)
          end
          table.insert(chunks, { "│", "ConfluenceTableSep" })
          for ci, cell in ipairs(cells) do
            table.insert(chunks, { cell, hl })
            table.insert(chunks, { "│", "ConfluenceTableSep" })
          end
          vim.api.nvim_buf_set_extmark(buf, ns, jln, 0, {
            virt_text = chunks,
            virt_text_pos = "overlay",
          })
        end
      end

      -- Bottom border below last row
      vim.api.nvim_buf_set_extmark(buf, ns, block_end - 1, 0, {
        virt_lines = { { { bot_border, "ConfluenceTableSep" } } },
      })

      ti = block_end + 1
    else
      ti = ti + 1
    end
    ::continue::
  end
end

-- ── Search (telescope) ──────────────────────────────────────

function M.search(query)
  if not M._load_config() then return end
  if not pcall(require, "telescope") then
    vim.notify("Telescope required", vim.log.levels.ERROR)
    return
  end

  local cql
  if query and query ~= "" then
    cql = 'type=page AND text~"' .. query:gsub('"', '\\"') .. '"'
  else
    cql = "type=page ORDER BY lastModified DESC"
  end

  vim.notify("Searching Confluence...")
  local data = M._api("GET",
    "/wiki/rest/api/content/search?cql=" .. url_encode(cql)
    .. "&expand=space,version&limit=25")
  if not data or not data.results then return end

  if #data.results == 0 then
    vim.notify("No pages found", vim.log.levels.WARN)
    return
  end

  local pickers = require("telescope.pickers")
  local finders = require("telescope.finders")
  local conf = require("telescope.config").values
  local actions = require("telescope.actions")
  local action_state = require("telescope.actions.state")
  local previewers = require("telescope.previewers")

  pickers.new({}, {
    prompt_title = query and ("Confluence: " .. query) or "Confluence: Recent",
    finder = finders.new_table({
      results = data.results,
      entry_maker = function(page)
        local space = page.space and page.space.key or "?"
        local ver = page.version and page.version.number or 0
        local disp = string.format("%-42s  %s v%d", page.title:sub(1, 42), space, ver)
        return { value = page, display = disp, ordinal = page.title .. " " .. space }
      end,
    }),
    sorter = conf.generic_sorter({}),
    previewer = previewers.new_buffer_previewer({
      title = "Page Preview",
      define_preview = function(self, entry)
        local pg = M._api("GET", "/wiki/rest/api/content/" .. entry.value.id .. "?expand=body.storage")
        if pg and pg.body then
          local md = M._storage_to_markdown(pg.body.storage.value or "")
          vim.api.nvim_buf_set_lines(self.state.bufnr, 0, -1, false, vim.split(md, "\n"))
          vim.bo[self.state.bufnr].filetype = "markdown"
        else
          vim.api.nvim_buf_set_lines(self.state.bufnr, 0, -1, false, { "Failed to load preview" })
        end
      end,
    }),
    attach_mappings = function(prompt_bufnr)
      actions.select_default:replace(function()
        actions.close(prompt_bufnr)
        local sel = action_state.get_selected_entry()
        if sel then M.view_page(sel.value.id) end
      end)
      return true
    end,
  }):find()
end

-- ── Browse spaces ───────────────────────────────────────────

function M.browse()
  if not M._load_config() then return end
  if not pcall(require, "telescope") then
    vim.notify("Telescope required", vim.log.levels.ERROR)
    return
  end

  vim.notify("Loading spaces...")
  local data = M._api("GET", "/wiki/rest/api/space?type=global&limit=50")
  if not data or not data.results then return end

  local pickers = require("telescope.pickers")
  local finders = require("telescope.finders")
  local conf = require("telescope.config").values
  local actions = require("telescope.actions")
  local action_state = require("telescope.actions.state")

  pickers.new({}, {
    prompt_title = "Confluence Spaces",
    finder = finders.new_table({
      results = data.results,
      entry_maker = function(space)
        local disp = string.format("%-8s %s", space.key, space.name)
        return { value = space, display = disp, ordinal = space.key .. " " .. space.name }
      end,
    }),
    sorter = conf.generic_sorter({}),
    attach_mappings = function(prompt_bufnr)
      actions.select_default:replace(function()
        actions.close(prompt_bufnr)
        local sel = action_state.get_selected_entry()
        if sel then M._browse_space(sel.value.key, sel.value.name) end
      end)
      return true
    end,
  }):find()
end

function M._browse_space(space_key, space_name)
  vim.notify("Loading pages in " .. space_key .. "...")
  local data = M._api("GET",
    "/wiki/rest/api/content?spaceKey=" .. space_key
    .. "&type=page&expand=version&limit=50&orderby=title")
  if not data or not data.results then return end

  local pickers = require("telescope.pickers")
  local finders = require("telescope.finders")
  local conf = require("telescope.config").values
  local actions = require("telescope.actions")
  local action_state = require("telescope.actions.state")
  local previewers = require("telescope.previewers")

  pickers.new({}, {
    prompt_title = "Pages in " .. space_name,
    finder = finders.new_table({
      results = data.results,
      entry_maker = function(page)
        local ver = page.version and page.version.number or 0
        return { value = page, display = page.title .. "  v" .. ver, ordinal = page.title }
      end,
    }),
    sorter = conf.generic_sorter({}),
    previewer = previewers.new_buffer_previewer({
      title = "Page Preview",
      define_preview = function(self, entry)
        local pg = M._api("GET", "/wiki/rest/api/content/" .. entry.value.id .. "?expand=body.storage")
        if pg and pg.body then
          local md = M._storage_to_markdown(pg.body.storage.value or "")
          vim.api.nvim_buf_set_lines(self.state.bufnr, 0, -1, false, vim.split(md, "\n"))
          vim.bo[self.state.bufnr].filetype = "markdown"
        end
      end,
    }),
    attach_mappings = function(prompt_bufnr)
      actions.select_default:replace(function()
        actions.close(prompt_bufnr)
        local sel = action_state.get_selected_entry()
        if sel then M.view_page(sel.value.id) end
      end)
      return true
    end,
  }):find()
end

-- ── View page ───────────────────────────────────────────────

function M.view_page(page_id)
  vim.notify("Loading page...")
  local page = M._api("GET",
    "/wiki/rest/api/content/" .. page_id .. "?expand=body.storage,version,space,_links")
  if not page then return end

  local md = M._storage_to_markdown(page.body and page.body.storage and page.body.storage.value or "")

  local space_key = page.space and page.space.key or "?"
  local ver = page.version and page.version.number or 1
  local header = "# " .. (page.title or "Untitled") .. "\n\n"
    .. "> **Space:** " .. space_key .. " | **Version:** " .. ver .. "\n\n---\n\n"

  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, vim.split(header .. md, "\n"))

  vim.bo[buf].filetype = "markdown"
  vim.bo[buf].buftype = "nofile"
  vim.bo[buf].modifiable = false
  vim.bo[buf].bufhidden = "wipe"

  vim.api.nvim_buf_set_var(buf, "confluence_page_id", page.id)
  vim.api.nvim_buf_set_var(buf, "confluence_version", ver)
  vim.api.nvim_buf_set_var(buf, "confluence_title", page.title or "")
  vim.api.nvim_buf_set_var(buf, "confluence_space_key", space_key)

  local web_url = ""
  if page._links and page._links.webui then
    web_url = "https://" .. M.domain .. "/wiki" .. page._links.webui
    vim.api.nvim_buf_set_var(buf, "confluence_url", web_url)
  end

  vim.api.nvim_set_current_buf(buf)

  -- Reader-friendly window options
  local win = vim.api.nvim_get_current_win()
  vim.wo[win].wrap = true
  vim.wo[win].linebreak = true
  vim.wo[win].conceallevel = 2
  vim.wo[win].number = false
  vim.wo[win].relativenumber = false
  vim.wo[win].signcolumn = "no"
  vim.wo[win].cursorline = true
  vim.wo[win].foldcolumn = "0"

  -- Apply visual styling
  M._style_buffer(buf)

  vim.keymap.set("n", "<leader>ce", function()
    vim.bo[buf].modifiable = not vim.bo[buf].modifiable
    vim.notify(vim.bo[buf].modifiable and "Edit mode ON" or "Edit mode OFF")
  end, { buffer = buf, desc = "Confluence: toggle edit" })

  vim.keymap.set("n", "<leader>cp", function()
    M._update_page_from_buffer(buf)
  end, { buffer = buf, desc = "Confluence: publish" })

  vim.keymap.set("n", "<leader>co", function()
    if web_url ~= "" then vim.ui.open(web_url)
    else vim.notify("No URL available", vim.log.levels.WARN) end
  end, { buffer = buf, desc = "Confluence: open in browser" })

  vim.keymap.set("n", "<leader>cr", function()
    M.view_page(page_id)
  end, { buffer = buf, desc = "Confluence: refresh" })

  vim.keymap.set("n", "<leader>cc", function()
    M._add_footer_comment(buf, page.id)
  end, { buffer = buf, desc = "Confluence: page comment" })

  vim.keymap.set("v", "<leader>cc", function()
    M._add_inline_comment(buf, page.id)
  end, { buffer = buf, desc = "Confluence: inline comment" })

  vim.keymap.set("n", "<leader>cv", function()
    M._view_comment_at_cursor(buf, page.id)
  end, { buffer = buf, desc = "Confluence: view comment" })

  vim.keymap.set("n", "]n", function() M._next_comment(1) end, { buffer = buf, desc = "Next comment" })
  vim.keymap.set("n", "[n", function() M._next_comment(-1) end, { buffer = buf, desc = "Prev comment" })

  vim.keymap.set("n", "q", function()
    vim.api.nvim_buf_delete(buf, { force = true })
  end, { buffer = buf, desc = "Close" })

  -- Fetch and render comments
  M._fetch_comments(page.id)
  M._render_comments(buf)

  local comment_count = #M._inline_comments + #M._footer_comments
  vim.notify(string.format(
    " %s | %s v%d | %d comments | cc=comment cv=view ce=edit q=close",
    page.title, space_key, ver, comment_count
  ))
end

-- ── Publish ─────────────────────────────────────────────────

function M.publish()
  if not M._load_config() then return end
  local bufnr = vim.api.nvim_get_current_buf()
  local ok, pid = pcall(vim.api.nvim_buf_get_var, bufnr, "confluence_page_id")
  if ok and pid then
    M._update_page_from_buffer(bufnr)
  else
    M._create_page_from_buffer(bufnr)
  end
end

function M._update_page_from_buffer(bufnr)
  local page_id = vim.b[bufnr].confluence_page_id
  local version = vim.b[bufnr].confluence_version or 1
  local title = vim.b[bufnr].confluence_title or "Untitled"

  local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
  local md = table.concat(lines, "\n")
  -- Strip the header we added when viewing
  md = md:gsub("^# [^\n]*\n+>[^\n]*\n+%-%-%-\n+", "")

  local storage = M._markdown_to_storage(md)
  local body = vim.fn.json_encode({
    version = { number = version + 1 },
    title = title,
    type = "page",
    body = { storage = { value = storage, representation = "storage" } },
  })

  vim.notify("Publishing...")
  local result = M._api("PUT", "/wiki/rest/api/content/" .. page_id, body)
  if result then
    vim.api.nvim_buf_set_var(bufnr, "confluence_version", version + 1)
    vim.bo[bufnr].modifiable = false
    vim.notify("Published! v" .. (version + 1))
  end
end

function M._create_page_from_buffer(bufnr)
  local spaces_data = M._api("GET", "/wiki/rest/api/space?type=global&limit=50")
  if not spaces_data or not spaces_data.results or #spaces_data.results == 0 then
    vim.notify("No spaces found", vim.log.levels.ERROR)
    return
  end

  local names = vim.tbl_map(function(s)
    return s.key .. " — " .. s.name
  end, spaces_data.results)

  vim.ui.select(names, { prompt = "Select space:" }, function(choice)
    if not choice then return end
    local space_key = choice:match("^(%S+)")

    vim.ui.input({ prompt = "Page title: " }, function(title)
      if not title or title == "" then return end

      local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
      local storage = M._markdown_to_storage(table.concat(lines, "\n"))
      local body = vim.fn.json_encode({
        type = "page",
        title = title,
        space = { key = space_key },
        body = { storage = { value = storage, representation = "storage" } },
      })

      vim.notify("Creating page...")
      local result = M._api("POST", "/wiki/rest/api/content", body)
      if result then
        vim.api.nvim_buf_set_var(bufnr, "confluence_page_id", result.id)
        vim.api.nvim_buf_set_var(bufnr, "confluence_version", 1)
        vim.api.nvim_buf_set_var(bufnr, "confluence_title", title)
        vim.api.nvim_buf_set_var(bufnr, "confluence_space_key", space_key)
        vim.notify("Created: " .. title .. " in " .. space_key)
      end
    end)
  end)
end

-- ── Setup ───────────────────────────────────────────────────

function M.setup_interactive()
  vim.ui.input({ prompt = "Confluence domain (e.g. company.atlassian.net): " }, function(domain)
    if not domain or domain == "" then return end
    vim.ui.input({ prompt = "Email: " }, function(email)
      if not email or email == "" then return end
      vim.ui.input({ prompt = "API token: " }, function(token)
        if not token or token == "" then return end

        local dir = vim.fn.expand("~/.config/confluence")
        vim.fn.mkdir(dir, "p")
        local path = dir .. "/config.json"
        local f = io.open(path, "w")
        if f then
          f:write(vim.fn.json_encode({ domain = domain, email = email, token = token }))
          f:close()
          vim.fn.system({ "chmod", "600", path })
        end

        M.domain = domain
        M.email = email
        M.token = token
        vim.notify("Confluence configured! Saved to " .. path)
      end)
    end)
  end)
end

-- ── Commands ────────────────────────────────────────────────

vim.api.nvim_create_user_command("Confluence", function(opts)
  local q = opts.args ~= "" and opts.args or nil
  M.search(q)
end, { nargs = "*", desc = "Search Confluence pages" })

vim.api.nvim_create_user_command("ConfluenceBrowse", function()
  M.browse()
end, { desc = "Browse Confluence spaces" })

vim.api.nvim_create_user_command("ConfluencePublish", function()
  M.publish()
end, { desc = "Publish buffer to Confluence" })

vim.api.nvim_create_user_command("ConfluenceSetup", function()
  M.setup_interactive()
end, { desc = "Configure Confluence credentials" })

return M
