-- Jira — Browse, view, and manage Jira tickets from Neovim
-- :Jira [query]        search tickets
-- :JiraMine            show tickets assigned to me
-- :JiraSetup           configure credentials

local M = {}

M.domain = nil
M.email = nil
M.token = nil
M._style_ns = vim.api.nvim_create_namespace("jira_style")

local function url_encode(s)
  return s:gsub("([^%w%-%.%_%~])", function(c)
    return string.format("%%%02X", string.byte(c))
  end)
end

-- ── Highlights (rose-pine compatible) ──────────────────────
vim.api.nvim_set_hl(0, "JiraH1", { default = true, bold = true, bg = "#26233a", fg = "#e0def4" })
vim.api.nvim_set_hl(0, "JiraH2", { default = true, bold = true, bg = "#1f1d2e", fg = "#c4a7e7" })
vim.api.nvim_set_hl(0, "JiraH3", { default = true, bold = true, fg = "#9ccfd8" })
vim.api.nvim_set_hl(0, "JiraMeta", { default = true, fg = "#908caa", italic = true })
vim.api.nvim_set_hl(0, "JiraMetaValue", { default = true, fg = "#e0def4" })
vim.api.nvim_set_hl(0, "JiraRule", { default = true, fg = "#6e6a86" })
vim.api.nvim_set_hl(0, "JiraCode", { default = true, bg = "#1a1826" })
vim.api.nvim_set_hl(0, "JiraCodeFence", { default = true, fg = "#6e6a86", bg = "#1a1826" })
vim.api.nvim_set_hl(0, "JiraCodeLabel", { default = true, fg = "#908caa", bg = "#1a1826", italic = true })
vim.api.nvim_set_hl(0, "JiraBlockquote", { default = true, bg = "#1f1d2e", italic = true })
vim.api.nvim_set_hl(0, "JiraBullet", { default = true, fg = "#c4a7e7", bold = true })
vim.api.nvim_set_hl(0, "JiraLink", { default = true, fg = "#31748f", underline = true })
vim.api.nvim_set_hl(0, "JiraTable", { default = true, bg = "#1f1d2e" })
vim.api.nvim_set_hl(0, "JiraTableHeader", { default = true, bg = "#26233a", bold = true })
vim.api.nvim_set_hl(0, "JiraTableSep", { default = true, fg = "#6e6a86" })
vim.api.nvim_set_hl(0, "JiraHeadingIcon", { default = true, fg = "#c4a7e7" })
vim.api.nvim_set_hl(0, "JiraStatusTodo", { default = true, fg = "#908caa" })
vim.api.nvim_set_hl(0, "JiraStatusProgress", { default = true, fg = "#31748f", bold = true })
vim.api.nvim_set_hl(0, "JiraStatusDone", { default = true, fg = "#9ccfd8", bold = true })
vim.api.nvim_set_hl(0, "JiraPriorityHigh", { default = true, fg = "#eb6f92", bold = true })
vim.api.nvim_set_hl(0, "JiraPriorityMed", { default = true, fg = "#f6c177" })
vim.api.nvim_set_hl(0, "JiraPriorityLow", { default = true, fg = "#31748f" })
vim.api.nvim_set_hl(0, "JiraCommentAuthor", { default = true, fg = "#c4a7e7", bold = true })
vim.api.nvim_set_hl(0, "JiraCommentDate", { default = true, fg = "#6e6a86", italic = true })
vim.api.nvim_set_hl(0, "JiraCommentBorder", { default = true, fg = "#6e6a86" })
vim.api.nvim_set_hl(0, "JiraKey", { default = true, fg = "#f6c177", bold = true })

-- ── Helpers ────────────────────────────────────────────────

local function format_date(iso)
  if not iso then return "?" end
  local y, m, d = iso:match("(%d+)%-(%d+)%-(%d+)")
  if not y then return iso:sub(1, 10) end
  local months = { "Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec" }
  return months[tonumber(m)] .. " " .. tonumber(d) .. ", " .. y
end

local function time_ago(iso)
  if not iso then return "" end
  local y, mo, d, h, mi = iso:match("(%d+)%-(%d+)%-(%d+)T(%d+):(%d+)")
  if not y then return "" end
  local t = os.time({ year = tonumber(y), month = tonumber(mo), day = tonumber(d), hour = tonumber(h), min = tonumber(mi) })
  local diff = os.difftime(os.time(), t)
  if diff < 60 then return "just now" end
  if diff < 3600 then return math.floor(diff / 60) .. "m ago" end
  if diff < 86400 then return math.floor(diff / 3600) .. "h ago" end
  if diff < 2592000 then return math.floor(diff / 86400) .. "d ago" end
  return format_date(iso)
end

function M._slugify(text)
  return text:lower()
    :gsub("[^%w%s%-]", "")
    :gsub("%s+", "-")
    :gsub("%-+", "-")
    :gsub("^%-", "")
    :gsub("%-$", "")
    :sub(1, 50)
end

local function wrap_text(text, width)
  width = width or 80
  local out = {}
  for _, line in ipairs(vim.split(text, "\n")) do
    if #line <= width
      or line:match("^[#>|`]")
      or line:match("^%s*[%-%*%d]")
      or line:match("^%s*$") then
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

-- ── Config ─────────────────────────────────────────────────

function M._load_config()
  if M.domain and M.email and M.token then return true end

  M.domain = vim.env.JIRA_DOMAIN
  M.email = vim.env.JIRA_EMAIL
  M.token = vim.env.JIRA_TOKEN
  if M.domain and M.email and M.token then return true end

  local path = vim.fn.expand("~/.config/jira/config.json")
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

  -- Fall back to Confluence config (same Atlassian instance)
  path = vim.fn.expand("~/.config/confluence/config.json")
  f = io.open(path, "r")
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
  vim.notify("Jira not configured. Run :JiraSetup", vim.log.levels.ERROR)
  return false
end

-- ── API ────────────────────────────────────────────────────

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

  local result = vim.system(args):wait()
  local output = result.stdout or ""

  local resp, status_str = output:match("(.-)__HTTP__(%d+)%s*$")
  if not resp then
    vim.notify("Jira API request failed", vim.log.levels.ERROR)
    return nil
  end

  local status = tonumber(status_str)
  if status == 404 then
    vim.notify("Not found", vim.log.levels.ERROR)
    return nil
  elseif status < 200 or status >= 300 then
    vim.notify("Jira API error (HTTP " .. status .. ")", vim.log.levels.ERROR)
    return nil
  end

  if resp == "" then return {} end
  local ok, data = pcall(vim.fn.json_decode, resp)
  if not ok then
    vim.notify("Failed to parse Jira response", vim.log.levels.ERROR)
    return nil
  end
  return data
end

-- ── ADF → Markdown ─────────────────────────────────────────

function M._adf_to_markdown(node)
  if type(node) ~= "table" then return "" end

  if node.type == "text" then
    local text = node.text or ""
    if node.marks then
      for _, mark in ipairs(node.marks) do
        if mark.type == "strong" then text = "**" .. text .. "**" end
        if mark.type == "em" then text = "*" .. text .. "*" end
        if mark.type == "code" then text = "`" .. text .. "`" end
        if mark.type == "strike" then text = "~~" .. text .. "~~" end
        if mark.type == "link" and mark.attrs then
          text = "[" .. text .. "](" .. (mark.attrs.href or "") .. ")"
        end
      end
    end
    return text
  end

  if node.type == "hardBreak" then return "\n" end
  if node.type == "rule" then return "\n---\n\n" end
  if node.type == "emoji" then return node.attrs and node.attrs.shortName or "" end
  if node.type == "mention" then return "@" .. (node.attrs and node.attrs.text or "user") end
  if node.type == "mediaSingle" or node.type == "mediaGroup" then return "[Attachment]\n\n" end
  if node.type == "media" then return "" end

  local children = {}
  if node.content then
    for _, child in ipairs(node.content) do
      table.insert(children, M._adf_to_markdown(child))
    end
  end
  local inner = table.concat(children)

  if node.type == "doc" then return inner end
  if node.type == "paragraph" then return inner .. "\n\n" end
  if node.type == "heading" then
    local level = node.attrs and node.attrs.level or 1
    return string.rep("#", level) .. " " .. inner .. "\n\n"
  end
  if node.type == "bulletList" then return inner end
  if node.type == "orderedList" then return inner end
  if node.type == "listItem" then
    local parts = {}
    for _, child in ipairs(node.content or {}) do
      local ct = M._adf_to_markdown(child):gsub("\n+$", "")
      if child.type == "bulletList" or child.type == "orderedList" then
        for _, sub in ipairs(vim.split(ct, "\n")) do
          table.insert(parts, "  " .. sub)
        end
      else
        table.insert(parts, ct)
      end
    end
    return "- " .. table.concat(parts, "\n") .. "\n"
  end
  if node.type == "codeBlock" then
    local lang = node.attrs and node.attrs.language or ""
    return "```" .. lang .. "\n" .. inner .. "\n```\n\n"
  end
  if node.type == "blockquote" then
    local quoted = inner:gsub("\n\n$", ""):gsub("\n", "\n> ")
    return "> " .. quoted .. "\n\n"
  end
  if node.type == "panel" then
    local ptype = node.attrs and node.attrs.panelType or "info"
    local quoted = inner:gsub("\n\n$", ""):gsub("\n", "\n> ")
    return "> **" .. ptype:upper() .. ":** " .. quoted .. "\n\n"
  end
  if node.type == "expand" then
    local title = node.attrs and node.attrs.title or "Details"
    return "**" .. title .. "**\n\n" .. inner
  end

  -- Tables
  if node.type == "table" then
    local rows = {}
    for _, row_node in ipairs(node.content or {}) do
      if row_node.type == "tableRow" then
        local cells = {}
        local is_header = false
        for _, cell_node in ipairs(row_node.content or {}) do
          if cell_node.type == "tableHeader" then is_header = true end
          local cell_text = ""
          for _, p in ipairs(cell_node.content or {}) do
            cell_text = cell_text .. M._adf_to_markdown(p):gsub("\n+$", "")
          end
          table.insert(cells, cell_text)
        end
        table.insert(rows, { cells = cells, header = is_header })
      end
    end
    if #rows == 0 then return "" end

    local col_widths = {}
    for _, row in ipairs(rows) do
      for j, cell in ipairs(row.cells) do
        col_widths[j] = math.max(col_widths[j] or 3, #cell)
      end
    end
    local tbl_lines = {}
    for i, row in ipairs(rows) do
      local padded = {}
      for j, cell in ipairs(row.cells) do
        local w = col_widths[j] or #cell
        table.insert(padded, cell .. string.rep(" ", w - #cell))
      end
      table.insert(tbl_lines, "| " .. table.concat(padded, " | ") .. " |")
      if row.header or (i == 1 and #rows > 1) then
        local sep = {}
        for j = 1, #row.cells do
          table.insert(sep, string.rep("-", col_widths[j] or 3))
        end
        table.insert(tbl_lines, "| " .. table.concat(sep, " | ") .. " |")
      end
    end
    return "\n" .. table.concat(tbl_lines, "\n") .. "\n\n"
  end

  return inner
end

-- ── HTML → Markdown (fallback) ─────────────────────────────

function M._html_to_markdown(html)
  if not html or html == "" then return "" end
  local s = html
  for i = 1, 6 do
    s = s:gsub('<h' .. i .. '[^>]*>(.-)</h' .. i .. '>', function(t)
      return "\n" .. string.rep("#", i) .. " " .. t:gsub("<[^>]+>", "") .. "\n"
    end)
  end
  s = s:gsub('<ul[^>]*>(.-)</ul>', function(list)
    local items = {}
    for item in list:gmatch('<li[^>]*>(.-)</li>') do
      table.insert(items, "- " .. item:gsub("<[^>]+>", ""):gsub("^%s+", ""):gsub("%s+$", ""))
    end
    return "\n" .. table.concat(items, "\n") .. "\n"
  end)
  s = s:gsub('<pre[^>]*>(.-)</pre>', function(code)
    return "\n```\n" .. code:gsub("<[^>]+>", "") .. "\n```\n"
  end)
  s = s:gsub('<strong[^>]*>(.-)</strong>', '**%1**')
  s = s:gsub('<em[^>]*>(.-)</em>', '*%1*')
  s = s:gsub('<code[^>]*>(.-)</code>', '`%1`')
  s = s:gsub('<a[^>]*href="([^"]*)"[^>]*>(.-)</a>', '[%2](%1)')
  s = s:gsub('<p[^>]*>(.-)</p>', '%1\n\n')
  s = s:gsub('<br%s*/?>', '\n')
  s = s:gsub('<hr%s*/?>', '\n---\n')
  s = s:gsub('<[^>]+>', '')
  s = s:gsub("&amp;", "&"):gsub("&lt;", "<"):gsub("&gt;", ">")
  s = s:gsub("&quot;", '"'):gsub("&nbsp;", " ")
  s = s:gsub("\n\n\n+", "\n\n"):gsub("^\n+", ""):gsub("\n+$", "\n")
  return s
end

-- ── Buffer styling ─────────────────────────────────────────

function M._style_buffer(buf)
  local ns = M._style_ns
  vim.api.nvim_buf_clear_namespace(buf, ns, 0, -1)

  local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
  local in_code = false

  for i, line in ipairs(lines) do
    local ln = i - 1

    if line:match("^```") then
      if not in_code then
        local lang = line:match("^```(%S+)")
        in_code = true
        vim.api.nvim_buf_add_highlight(buf, ns, "JiraCodeFence", ln, 0, -1)
        if lang and lang ~= "" then
          vim.api.nvim_buf_set_extmark(buf, ns, ln, 0, {
            virt_text = { { " " .. lang .. " ", "JiraCodeLabel" } },
            virt_text_pos = "right_align",
          })
        end
      else
        in_code = false
        vim.api.nvim_buf_add_highlight(buf, ns, "JiraCodeFence", ln, 0, -1)
      end
    elseif in_code then
      vim.api.nvim_buf_add_highlight(buf, ns, "JiraCode", ln, 0, -1)

    elseif line:match("^# ") then
      local text = line:match("^# (.+)")
      vim.api.nvim_buf_set_extmark(buf, ns, ln, 0, {
        virt_text = { { "◆ ", "JiraHeadingIcon" }, { text, "JiraH1" } },
        virt_text_pos = "overlay", line_hl_group = "JiraH1",
      })
    elseif line:match("^## ") then
      local text = line:match("^## (.+)")
      vim.api.nvim_buf_set_extmark(buf, ns, ln, 0, {
        virt_text = { { "◇ ", "JiraHeadingIcon" }, { text, "JiraH2" } },
        virt_text_pos = "overlay", line_hl_group = "JiraH2",
      })
    elseif line:match("^### ") then
      local text = line:match("^### (.+)")
      vim.api.nvim_buf_set_extmark(buf, ns, ln, 0, {
        virt_text = { { "▸ ", "JiraHeadingIcon" }, { text, "JiraH3" } },
        virt_text_pos = "overlay",
      })

    elseif line:match("^%-%-%-") and line:match("^%-+$") then
      local width = math.max(60, vim.o.columns - 10)
      vim.api.nvim_buf_set_extmark(buf, ns, ln, 0, {
        virt_text = { { string.rep("─", width), "JiraRule" } },
        virt_text_pos = "overlay",
      })

    -- Comment borders
    elseif line:match("^┌ ") then
      local border_end = #("┌") + 1
      vim.api.nvim_buf_add_highlight(buf, ns, "JiraCommentBorder", ln, 0, border_end)
      local dot_pos = line:find("•")
      if dot_pos then
        vim.api.nvim_buf_add_highlight(buf, ns, "JiraCommentAuthor", ln, border_end, dot_pos - 2)
        vim.api.nvim_buf_add_highlight(buf, ns, "JiraCommentDate", ln, dot_pos - 1, -1)
      else
        vim.api.nvim_buf_add_highlight(buf, ns, "JiraCommentAuthor", ln, border_end, -1)
      end
    elseif line:match("^│") then
      vim.api.nvim_buf_add_highlight(buf, ns, "JiraCommentBorder", ln, 0, #("│"))
    elseif line:match("^└") then
      vim.api.nvim_buf_add_highlight(buf, ns, "JiraCommentBorder", ln, 0, -1)

    -- Metadata fields
    elseif line:match("^  %u%l+:") then
      local colon = line:find(":")
      if colon then
        vim.api.nvim_buf_add_highlight(buf, ns, "JiraMeta", ln, 0, colon)
        vim.api.nvim_buf_add_highlight(buf, ns, "JiraMetaValue", ln, colon, -1)
        -- Status-specific coloring
        if line:match("^  Status:") then
          local val = line:sub(colon + 1):gsub("^%s+", ""):lower()
          if val:match("done") or val:match("closed") or val:match("resolved") then
            vim.api.nvim_buf_add_highlight(buf, ns, "JiraStatusDone", ln, colon, -1)
          elseif val:match("progress") or val:match("review") or val:match("active") then
            vim.api.nvim_buf_add_highlight(buf, ns, "JiraStatusProgress", ln, colon, -1)
          end
        end
        if line:match("^  Priority:") then
          local val = line:sub(colon + 1):gsub("^%s+", ""):lower()
          if val:match("high") or val:match("critical") or val:match("blocker") then
            vim.api.nvim_buf_add_highlight(buf, ns, "JiraPriorityHigh", ln, colon, -1)
          elseif val:match("medium") then
            vim.api.nvim_buf_add_highlight(buf, ns, "JiraPriorityMed", ln, colon, -1)
          elseif val:match("low") then
            vim.api.nvim_buf_add_highlight(buf, ns, "JiraPriorityLow", ln, colon, -1)
          end
        end
      end

    -- Ticket key (first line)
    elseif line:match("^%u+%-%d+") then
      local s, e = line:find("^%u+%-%d+")
      if s then vim.api.nvim_buf_add_highlight(buf, ns, "JiraKey", ln, s - 1, e) end

    elseif line:match("^> ") then
      vim.api.nvim_buf_add_highlight(buf, ns, "JiraBlockquote", ln, 0, -1)

    elseif line:match("^%s*[%-%*] ") then
      local s, e = line:find("[%-%*]")
      if s then vim.api.nvim_buf_add_highlight(buf, ns, "JiraBullet", ln, s - 1, e) end

    elseif line:match("^%s*%d+%. ") then
      local s, e = line:find("%d+%.")
      if s then vim.api.nvim_buf_add_highlight(buf, ns, "JiraBullet", ln, s - 1, e) end

    elseif line:match("^|.*|%s*$") then
      -- tables handled in second pass

    else
      local pos = 1
      while true do
        local s, e = line:find("%[.-%]%(.-%)"), pos
        if not s then break end
        vim.api.nvim_buf_add_highlight(buf, ns, "JiraLink", ln, s - 1, e)
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
        goto jira_tbl_continue
      end

      local parts = {}
      for c = 1, #col_widths do
        table.insert(parts, string.rep("─", col_widths[c]))
      end
      local top_border = "┌" .. table.concat(parts, "┬") .. "┐"
      local mid_border = "├" .. table.concat(parts, "┼") .. "┤"
      local bot_border = "└" .. table.concat(parts, "┴") .. "┘"

      vim.api.nvim_buf_set_extmark(buf, ns, block_start - 1, 0, {
        virt_lines_above = true,
        virt_lines = { { { top_border, "JiraTableSep" } } },
      })

      for j = block_start, block_end do
        local jln = j - 1
        if lines[j]:match("^|[%s%-:|]+|%s*$") then
          vim.api.nvim_buf_set_extmark(buf, ns, jln, 0, {
            virt_text = { { mid_border, "JiraTableSep" } },
            virt_text_pos = "overlay",
          })
        else
          local is_header = j < block_end and lines[j + 1]:match("^|[%s%-:|]+|%s*$")
          local hl = is_header and "JiraTableHeader" or "JiraTable"
          local chunks = {}
          local cells = {}
          for cell in lines[j]:gmatch("|([^|]+)") do
            table.insert(cells, cell)
          end
          table.insert(chunks, { "│", "JiraTableSep" })
          for _, cell in ipairs(cells) do
            table.insert(chunks, { cell, hl })
            table.insert(chunks, { "│", "JiraTableSep" })
          end
          vim.api.nvim_buf_set_extmark(buf, ns, jln, 0, {
            virt_text = chunks,
            virt_text_pos = "overlay",
          })
        end
      end

      vim.api.nvim_buf_set_extmark(buf, ns, block_end - 1, 0, {
        virt_lines = { { { bot_border, "JiraTableSep" } } },
      })

      ti = block_end + 1
    else
      ti = ti + 1
    end
    ::jira_tbl_continue::
  end
end

-- ── View ticket ────────────────────────────────────────────

function M.view_ticket(key)
  vim.notify("Loading " .. key .. "...")
  local issue = M._api("GET",
    "/rest/api/3/issue/" .. key
    .. "?fields=summary,status,assignee,reporter,priority,issuetype,created,updated,description,comment,labels,fixVersions,project"
    .. "&expand=renderedFields")
  if not issue or not issue.fields then return end

  local f = issue.fields
  local summary = f.summary or "Untitled"
  local status = type(f.status) == "table" and f.status.name or "?"
  local assignee = type(f.assignee) == "table" and f.assignee.displayName or "Unassigned"
  local reporter = type(f.reporter) == "table" and f.reporter.displayName or "?"
  local priority = type(f.priority) == "table" and f.priority.name or "?"
  local itype = type(f.issuetype) == "table" and f.issuetype.name or "?"
  local project = type(f.project) == "table" and f.project.key or "?"
  local labels = type(f.labels) == "table" and #f.labels > 0 and table.concat(f.labels, ", ") or nil
  local created = format_date(f.created)
  local updated = format_date(f.updated)

  local content = {}
  table.insert(content, key .. "  " .. summary)
  table.insert(content, "")
  table.insert(content, "  Status:   " .. status)
  table.insert(content, "  Type:     " .. itype)
  table.insert(content, "  Priority: " .. priority)
  table.insert(content, "  Assignee: " .. assignee)
  table.insert(content, "  Reporter: " .. reporter)
  if labels then
    table.insert(content, "  Labels:   " .. labels)
  end
  table.insert(content, "  Created:  " .. created)
  table.insert(content, "  Updated:  " .. updated)
  table.insert(content, "")
  table.insert(content, "---")
  table.insert(content, "")

  -- Description (v3: ADF in fields, HTML in renderedFields)
  local desc_md = ""
  if f.description and type(f.description) == "table" then
    desc_md = M._adf_to_markdown(f.description)
  elseif issue.renderedFields and issue.renderedFields.description
    and issue.renderedFields.description ~= "" then
    desc_md = M._html_to_markdown(issue.renderedFields.description)
  elseif f.description and type(f.description) == "string" then
    desc_md = f.description
  end
  desc_md = wrap_text(desc_md, 80)
  if desc_md ~= "" then
    for _, line in ipairs(vim.split(desc_md, "\n")) do
      table.insert(content, line)
    end
  else
    table.insert(content, "*No description*")
    table.insert(content, "")
  end

  -- Comments
  local comments = f.comment and f.comment.comments or {}
  if #comments > 0 then
    table.insert(content, "")
    table.insert(content, "---")
    table.insert(content, "")
    table.insert(content, "## Comments (" .. #comments .. ")")
    table.insert(content, "")

    for _, c in ipairs(comments) do
      local author = c.author and c.author.displayName or "?"
      local ago = time_ago(c.created)
      table.insert(content, "┌ " .. author .. " • " .. ago)

      local body = ""
      if c.body and type(c.body) == "table" then
        body = M._adf_to_markdown(c.body)
      elseif c.body and type(c.body) == "string" then
        body = c.body
      end
      body = wrap_text(body, 76)
      for _, line in ipairs(vim.split(body:gsub("\n+$", ""), "\n")) do
        table.insert(content, "│ " .. line)
      end
      table.insert(content, "└")
      table.insert(content, "")
    end
  end

  table.insert(content, "---")
  table.insert(content, "")
  table.insert(content, "  jb=branch  jc=comment  js=status  jo=open  jr=refresh  q=close")

  -- Create buffer
  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, content)

  vim.bo[buf].filetype = "markdown"
  vim.bo[buf].buftype = "nofile"
  vim.bo[buf].modifiable = false
  vim.bo[buf].bufhidden = "wipe"
  vim.api.nvim_buf_set_var(buf, "jira_key", key)
  vim.api.nvim_buf_set_var(buf, "jira_summary", summary)
  vim.api.nvim_buf_set_var(buf, "jira_project", project)

  local web_url = "https://" .. M.domain .. "/browse/" .. key

  vim.api.nvim_set_current_buf(buf)

  local win = vim.api.nvim_get_current_win()
  vim.wo[win].wrap = true
  vim.wo[win].linebreak = true
  vim.wo[win].conceallevel = 2
  vim.wo[win].number = false
  vim.wo[win].relativenumber = false
  vim.wo[win].signcolumn = "no"
  vim.wo[win].cursorline = true
  vim.wo[win].foldcolumn = "0"

  M._style_buffer(buf)

  -- Keymaps
  vim.keymap.set("n", "<leader>jb", function()
    M._create_branch(key, summary)
  end, { buffer = buf, desc = "Jira: create branch" })

  vim.keymap.set("n", "<leader>jc", function()
    M._add_comment(buf, key)
  end, { buffer = buf, desc = "Jira: add comment" })

  vim.keymap.set("n", "<leader>js", function()
    M._update_status(buf, key)
  end, { buffer = buf, desc = "Jira: update status" })

  vim.keymap.set("n", "<leader>jo", function()
    vim.ui.open(web_url)
  end, { buffer = buf, desc = "Jira: open in browser" })

  vim.keymap.set("n", "<leader>jr", function()
    M.view_ticket(key)
  end, { buffer = buf, desc = "Jira: refresh" })

  vim.keymap.set("n", "q", function()
    vim.api.nvim_buf_delete(buf, { force = true })
  end, { buffer = buf, desc = "Close" })

  vim.notify(string.format(
    " %s │ %s │ %s │ %d comments │ jb=branch jc=comment js=status q=close",
    key, status, assignee, #comments
  ))
end

-- ── Add comment ────────────────────────────────────────────

function M._add_comment(buf, key)
  local w = math.min(70, vim.o.columns - 4)
  local input_buf = vim.api.nvim_create_buf(false, true)
  vim.bo[input_buf].filetype = "markdown"

  local win = vim.api.nvim_open_win(input_buf, true, {
    relative = "editor",
    row = math.floor(vim.o.lines * 0.3),
    col = math.floor((vim.o.columns - w) / 2),
    width = w, height = 8,
    style = "minimal", border = "rounded",
    title = " Comment on " .. key .. " ", title_pos = "center",
  })

  vim.keymap.set("n", "<leader>s", function()
    local lines = vim.api.nvim_buf_get_lines(input_buf, 0, -1, false)
    local text = table.concat(lines, "\n"):gsub("^%s+", ""):gsub("%s+$", "")
    if text == "" then
      vim.notify("Empty comment", vim.log.levels.WARN)
      return
    end

    if vim.api.nvim_win_is_valid(win) then vim.api.nvim_win_close(win, true) end

    local body = vim.fn.json_encode({
      body = {
        type = "doc",
        version = 1,
        content = {
          {
            type = "paragraph",
            content = {
              { type = "text", text = text }
            }
          }
        }
      }
    })

    vim.notify("Posting comment...")
    local result = M._api("POST", "/rest/api/3/issue/" .. key .. "/comment", body)
    if result then
      vim.notify("Comment added to " .. key)
      M.view_ticket(key)
    end
  end, { buffer = input_buf, desc = "Submit comment" })

  vim.keymap.set("n", "q", function()
    if vim.api.nvim_win_is_valid(win) then vim.api.nvim_win_close(win, true) end
  end, { buffer = input_buf })
  vim.keymap.set("n", "<Esc>", function()
    if vim.api.nvim_win_is_valid(win) then vim.api.nvim_win_close(win, true) end
  end, { buffer = input_buf })

  vim.cmd("startinsert")
  vim.notify("Type comment, <leader>s to submit, q/Esc to cancel")
end

-- ── Update status ──────────────────────────────────────────

function M._update_status(buf, key)
  vim.notify("Loading transitions...")
  local data = M._api("GET", "/rest/api/3/issue/" .. key .. "/transitions")
  if not data or not data.transitions or #data.transitions == 0 then
    vim.notify("No transitions available", vim.log.levels.WARN)
    return
  end

  local items = {}
  for _, t in ipairs(data.transitions) do
    table.insert(items, { id = t.id, name = t.name, to = t.to and t.to.name or "" })
  end

  vim.ui.select(items, {
    prompt = "Move " .. key .. " to:",
    format_item = function(item)
      return item.name .. (item.to ~= "" and (" → " .. item.to) or "")
    end,
  }, function(choice)
    if not choice then return end
    local body = vim.fn.json_encode({ transition = { id = choice.id } })
    vim.notify("Updating status...")
    local result = M._api("POST", "/rest/api/3/issue/" .. key .. "/transitions", body)
    if result then
      vim.notify(key .. " → " .. choice.name)
      M.view_ticket(key)
    end
  end)
end

-- ── Create branch ──────────────────────────────────────────

function M._create_branch(key, summary)
  if not pcall(require, "telescope") then
    vim.notify("Telescope required", vim.log.levels.ERROR)
    return
  end

  vim.notify("Loading repos...")

  -- Get all repos (personal + org) via GitHub API
  local repo_result = vim.system({
    "gh", "api", "user/repos?per_page=100&type=all&sort=updated&direction=desc",
    "--paginate", "--jq", ".[].full_name",
  }):wait()

  if repo_result.code ~= 0 or not repo_result.stdout or repo_result.stdout == "" then
    vim.notify("Failed to list repos (check gh auth)", vim.log.levels.ERROR)
    return
  end

  local seen = {}
  local repos = {}
  for _, r in ipairs(vim.split(repo_result.stdout, "\n")) do
    if r ~= "" and not seen[r] then
      seen[r] = true
      table.insert(repos, r)
    end
  end

  local pickers = require("telescope.pickers")
  local finders = require("telescope.finders")
  local conf = require("telescope.config").values
  local actions = require("telescope.actions")
  local action_state = require("telescope.actions.state")

  pickers.new({}, {
    prompt_title = "Create branch for " .. key .. " — pick repo",
    finder = finders.new_table({ results = repos }),
    sorter = conf.generic_sorter({}),
    attach_mappings = function(prompt_bufnr)
      actions.select_default:replace(function()
        actions.close(prompt_bufnr)
        local sel = action_state.get_selected_entry()
        if not sel then return end
        local repo = sel[1]

        vim.notify("Getting info for " .. repo .. "...")

        -- Get highest issue/PR number for next PR number
        local num_result = vim.system({
          "gh", "api",
          "repos/" .. repo .. "/issues?state=all&per_page=1&sort=created&direction=desc",
          "--jq", ".[0].number",
        }):wait()
        local num_str = (num_result.stdout or ""):gsub("%s+$", "")
        local latest = tonumber(num_str) or 0
        local next_num = latest + 1

        -- Get default branch name
        local branch_result = vim.system({
          "gh", "api", "repos/" .. repo,
          "--jq", ".default_branch",
        }):wait()
        local default_branch = (branch_result.stdout or ""):gsub("%s+$", "")
        if default_branch == "" then default_branch = "main" end

        -- Get SHA of default branch
        local sha_result = vim.system({
          "gh", "api", "repos/" .. repo .. "/git/ref/heads/" .. default_branch,
          "--jq", ".object.sha",
        }):wait()
        local sha = (sha_result.stdout or ""):gsub("%s+$", "")
        if sha == "" then
          vim.notify("Failed to get branch SHA", vim.log.levels.ERROR)
          return
        end

        local slug = M._slugify(summary)
        local branch_name = "PR" .. next_num .. "-" .. slug

        vim.ui.input({ prompt = "Branch name: ", default = branch_name }, function(name)
          if not name or name == "" then return end

          vim.notify("Creating branch " .. name .. " in " .. repo .. "...")
          local create_result = vim.system({
            "gh", "api", "repos/" .. repo .. "/git/refs",
            "-f", "ref=refs/heads/" .. name,
            "-f", "sha=" .. sha,
          }):wait()

          if create_result.code ~= 0 then
            vim.notify("Failed to create branch: " .. (create_result.stderr or ""), vim.log.levels.ERROR)
            return
          end

          vim.fn.setreg("+", name)
          vim.notify("Branch created: " .. name .. " in " .. repo .. " (copied to clipboard)")
        end)
      end)
      return true
    end,
  }):find()
end

-- ── Browse & Filter ────────────────────────────────────────

function M._build_jql(filters)
  local parts = {}

  if filters.text and filters.text ~= "" then
    table.insert(parts, 'text ~ "' .. filters.text:gsub('"', '\\"') .. '"')
  end

  if filters.assignee == "me" then
    table.insert(parts, "assignee = currentUser()")
  elseif filters.assignee == "unassigned" then
    table.insert(parts, "assignee is EMPTY")
  end

  if filters.status == "open" then
    table.insert(parts, 'statusCategory != "Done"')
  elseif filters.status == "todo" then
    table.insert(parts, 'statusCategory = "To Do"')
  elseif filters.status == "progress" then
    table.insert(parts, 'statusCategory = "In Progress"')
  elseif filters.status == "done" then
    table.insert(parts, 'statusCategory = "Done"')
  end

  if filters.project and filters.project ~= "" then
    table.insert(parts, 'project = "' .. filters.project .. '"')
  end

  if filters.sprint == "active" then
    table.insert(parts, "sprint in openSprints()")
  elseif filters.sprint == "future" then
    table.insert(parts, "sprint in futureSprints()")
  elseif filters.sprint == "closed" then
    table.insert(parts, "sprint in closedSprints()")
  elseif type(filters.sprint) == "number" then
    table.insert(parts, "sprint = " .. filters.sprint)
  end

  local jql = table.concat(parts, " AND ")
  if jql ~= "" then jql = jql .. " " end
  jql = jql .. "ORDER BY updated DESC"
  return jql
end

function M.browse(filters)
  filters = filters or {}
  if not M._load_config() then return end
  if not pcall(require, "telescope") then
    vim.notify("Telescope required", vim.log.levels.ERROR)
    return
  end

  local jql = M._build_jql(filters)
  vim.notify("Loading tickets...")

  local data = M._api("GET",
    "/rest/api/3/search/jql?jql=" .. url_encode(jql)
    .. "&fields=summary,status,assignee,priority,issuetype,updated&maxResults=50")
  if not data or not data.issues then return end

  if #data.issues == 0 then
    vim.notify("No tickets found", vim.log.levels.WARN)
    return
  end

  M._show_picker(data.issues, filters)
end

function M.search(query)
  if query and query ~= "" then
    M.browse({ text = query })
  else
    M.browse({ status = "open" })
  end
end

function M.my_tickets()
  M.browse({ assignee = "me", status = "open" })
end

function M._show_picker(issues, filters)
  filters = filters or {}

  local pickers = require("telescope.pickers")
  local finders = require("telescope.finders")
  local conf = require("telescope.config").values
  local actions = require("telescope.actions")
  local action_state = require("telescope.actions.state")
  local previewers = require("telescope.previewers")

  local status_icon = function(s)
    if not s or not s.statusCategory then return "○" end
    local cat = s.statusCategory.key
    if cat == "done" then return "✓" end
    if cat == "indeterminate" then return "●" end
    return "○"
  end

  -- Build title showing active filters
  local title_parts = { "Jira" }
  if filters.text then
    table.insert(title_parts, '"' .. filters.text .. '"')
  end
  if filters.assignee == "me" then table.insert(title_parts, "@me")
  elseif filters.assignee == "unassigned" then table.insert(title_parts, "@unassigned")
  else table.insert(title_parts, "@all") end
  if filters.status == "open" then table.insert(title_parts, "open")
  elseif filters.status == "todo" then table.insert(title_parts, "to do")
  elseif filters.status == "progress" then table.insert(title_parts, "in progress")
  elseif filters.status == "done" then table.insert(title_parts, "done")
  else table.insert(title_parts, "any status") end
  if filters.project then table.insert(title_parts, filters.project) end
  if filters.sprint == "active" then table.insert(title_parts, "active sprint")
  elseif filters.sprint == "future" then table.insert(title_parts, "future sprint")
  elseif filters.sprint == "closed" then table.insert(title_parts, "closed sprint")
  elseif type(filters.sprint) == "number" then table.insert(title_parts, "sprint #" .. filters.sprint)
  end
  table.insert(title_parts, #issues .. " results")
  local title = table.concat(title_parts, " │ ")

  local function pick_filter(prompt_bufnr, label, options, current, on_pick)
    actions.close(prompt_bufnr)
    vim.ui.select(options, {
      prompt = label .. ":",
      format_item = function(item)
        local mark = item.value == current and "● " or "  "
        return mark .. item.label
      end,
    }, function(choice)
      if choice then
        local f = {}
        for k, v in pairs(filters) do f[k] = v end
        on_pick(f, choice.value)
        M.browse(f)
      else
        M._show_picker(issues, filters)
      end
    end)
  end

  pickers.new({}, {
    prompt_title = title,
    finder = finders.new_table({
      results = issues,
      entry_maker = function(issue)
        local fi = issue.fields
        local icon = status_icon(fi.status)
        local status = fi.status and fi.status.name or "?"
        local assignee = (type(fi.assignee) == "table" and fi.assignee.displayName) or "Unassigned"
        local disp = string.format("%s %-12s %-14s %-16s %s",
          icon, issue.key, status, assignee:sub(1, 15), (fi.summary or ""):sub(1, 50))
        return {
          value = issue,
          display = disp,
          ordinal = issue.key .. " " .. (fi.summary or "") .. " " .. assignee,
        }
      end,
    }),
    sorter = conf.generic_sorter({}),
    previewer = previewers.new_buffer_previewer({
      title = "Ticket Preview",
      define_preview = function(self, entry)
        local fi = entry.value.fields
        local preview = {
          entry.value.key .. "  " .. (fi.summary or ""),
          "",
          "  Status:   " .. (type(fi.status) == "table" and fi.status.name or "?"),
          "  Type:     " .. (type(fi.issuetype) == "table" and fi.issuetype.name or "?"),
          "  Priority: " .. (type(fi.priority) == "table" and fi.priority.name or "?"),
          "  Assignee: " .. (type(fi.assignee) == "table" and fi.assignee.displayName or "Unassigned"),
          "  Updated:  " .. format_date(fi.updated),
        }
        vim.api.nvim_buf_set_lines(self.state.bufnr, 0, -1, false, preview)
        vim.bo[self.state.bufnr].filetype = "markdown"
      end,
    }),
    attach_mappings = function(prompt_bufnr, map)
      local function filter_assignee()
        pick_filter(prompt_bufnr, "Assignee", {
          { label = "All", value = nil },
          { label = "Me", value = "me" },
          { label = "Unassigned", value = "unassigned" },
        }, filters.assignee, function(f, val) f.assignee = val end)
      end
      map("i", "<C-a>", filter_assignee)
      map("n", "<C-a>", filter_assignee)

      local function filter_status()
        pick_filter(prompt_bufnr, "Status", {
          { label = "All", value = nil },
          { label = "Open (not done)", value = "open" },
          { label = "To Do", value = "todo" },
          { label = "In Progress", value = "progress" },
          { label = "Done", value = "done" },
        }, filters.status, function(f, val) f.status = val end)
      end
      map("i", "<C-e>", filter_status)
      map("n", "<C-e>", filter_status)

      local function filter_project()
        actions.close(prompt_bufnr)
        vim.notify("Loading projects...")
        local proj_data = M._api("GET", "/rest/api/3/project?maxResults=50&orderBy=name")
        if not proj_data then M._show_picker(issues, filters); return end

        local choices = { { label = "All projects", value = nil } }
        for _, p in ipairs(proj_data) do
          table.insert(choices, { label = p.key .. " — " .. (p.name or ""), value = p.key })
        end

        vim.ui.select(choices, {
          prompt = "Project:",
          format_item = function(item)
            local mark = item.value == filters.project and "● " or "  "
            return mark .. item.label
          end,
        }, function(choice)
          if choice then
            local f = {}
            for k, v in pairs(filters) do f[k] = v end
            f.project = choice.value
            M.browse(f)
          else
            M._show_picker(issues, filters)
          end
        end)
      end
      map("i", "<C-o>", filter_project)
      map("n", "<C-o>", filter_project)

      local function filter_sprint()
        actions.close(prompt_bufnr)

        local board_id
        if filters.project and filters.project ~= "" then
          local board_data = M._api("GET",
            "/rest/agile/1.0/board?projectKeyOrId=" .. url_encode(filters.project) .. "&maxResults=1")
          if board_data and board_data.values and #board_data.values > 0 then
            board_id = board_data.values[1].id
          end
        end

        local base_choices = {
          { label = "All sprints", value = nil },
          { label = "Active sprint", value = "active" },
          { label = "Future sprints", value = "future" },
          { label = "Closed sprints", value = "closed" },
        }

        if board_id then
          vim.notify("Loading sprints...")
          local sprint_data = M._api("GET",
            "/rest/agile/1.0/board/" .. board_id .. "/sprint?state=active,future&maxResults=20")
          if sprint_data and sprint_data.values then
            for _, s in ipairs(sprint_data.values) do
              local state_tag = s.state == "active" and " (active)" or ""
              table.insert(base_choices, {
                label = s.name .. state_tag,
                value = s.id,
              })
            end
          end
        end

        vim.ui.select(base_choices, {
          prompt = "Sprint:",
          format_item = function(item)
            local mark = item.value == filters.sprint and "● " or "  "
            return mark .. item.label
          end,
        }, function(choice)
          if choice then
            local f = {}
            for k, v in pairs(filters) do f[k] = v end
            f.sprint = choice.value
            M.browse(f)
          else
            M._show_picker(issues, filters)
          end
        end)
      end
      map("i", "<C-r>", filter_sprint)
      map("n", "<C-r>", filter_sprint)

      actions.select_default:replace(function()
        actions.close(prompt_bufnr)
        local sel = action_state.get_selected_entry()
        if sel then M.view_ticket(sel.value.key) end
      end)

      return true
    end,
  }):find()
end

-- ── Setup ──────────────────────────────────────────────────

function M.setup_interactive()
  vim.ui.input({ prompt = "Jira domain (e.g. company.atlassian.net): " }, function(domain)
    if not domain or domain == "" then return end
    vim.ui.input({ prompt = "Email: " }, function(email)
      if not email or email == "" then return end
      vim.ui.input({ prompt = "API token: " }, function(token)
        if not token or token == "" then return end

        local dir = vim.fn.expand("~/.config/jira")
        vim.fn.mkdir(dir, "p")
        local path = dir .. "/config.json"
        local fh = io.open(path, "w")
        if fh then
          fh:write(vim.fn.json_encode({ domain = domain, email = email, token = token }))
          fh:close()
          vim.fn.system("chmod 600 " .. vim.fn.shellescape(path))
          M.domain = domain
          M.email = email
          M.token = token
          vim.notify("Jira configured! Saved to " .. path)
        end
      end)
    end)
  end)
end

-- ── Commands ───────────────────────────────────────────────

vim.api.nvim_create_user_command("Jira", function(opts)
  if opts.args ~= "" then
    M.search(opts.args)
  else
    M.browse({ status = "open" })
  end
end, { nargs = "?" })

vim.api.nvim_create_user_command("JiraMine", function()
  M.my_tickets()
end, {})

vim.api.nvim_create_user_command("JiraSetup", function()
  M.setup_interactive()
end, {})

return M
