-- PR Review — GitHub PR review inside Neovim
-- Same gitsigns red/green view as review.lua + inline comments, replies, resolve

local M = {}
local review = require("config.review")

M.active = false
M.pr_number = nil
M.pr_info = nil
M.threads = {}
M.file_threads = {}
M.line_maps = {}
M.merge_base = nil
M.original_branch = nil
M.stashed = false
M.ns = vim.api.nvim_create_namespace("pr_review_comments")
M.augroup = vim.api.nvim_create_augroup("PrReview", { clear = true })
M.reviewed = {}
M.panel_buf = nil
M.panel_win = nil
M.file_stats = {}
M.panel_collapsed = {}

local _toplevel = nil

-- ── Highlights ──────────────────────────────────────────────

local function setup_highlights()
  vim.api.nvim_set_hl(0, "PrCommentVirt", { link = "DiagnosticVirtualTextInfo", default = true })
  vim.api.nvim_set_hl(0, "PrCommentAuthor", { link = "Special", default = true })
  vim.api.nvim_set_hl(0, "PrCommentResolved", { link = "DiagnosticVirtualTextHint", default = true })
  vim.api.nvim_set_hl(0, "PrThreadTitle", { link = "Title", default = true })
  vim.api.nvim_set_hl(0, "PrThreadAuthor", { link = "Keyword", default = true })
  vim.api.nvim_set_hl(0, "PrThreadSep", { link = "NonText", default = true })
  vim.api.nvim_set_hl(0, "PrPanelTitle", { link = "Title", default = true })
  vim.api.nvim_set_hl(0, "PrPanelSep", { link = "NonText", default = true })
  vim.api.nvim_set_hl(0, "PrPanelFile", { link = "Normal", default = true })
  vim.api.nvim_set_hl(0, "PrPanelReviewed", { link = "DiagnosticOk", default = true })
  vim.api.nvim_set_hl(0, "PrPanelCurrent", { link = "CursorLine", default = true })
  vim.api.nvim_set_hl(0, "PrPanelCounter", { link = "DiagnosticInfo", default = true })
  vim.api.nvim_set_hl(0, "PrPanelAdd", { fg = "#a6e3a1", default = true })
  vim.api.nvim_set_hl(0, "PrPanelDel", { fg = "#f38ba8", default = true })
  vim.api.nvim_set_hl(0, "PrPanelDir", { link = "Directory", default = true })
  vim.api.nvim_set_hl(0, "PrPanelDirArrow", { link = "NonText", default = true })
  vim.api.nvim_set_hl(0, "PrPanelComment", { link = "DiagnosticInfo", default = true })
  vim.api.nvim_set_hl(0, "PrPanelUnresolved", { link = "DiagnosticWarn", default = true })
  vim.api.nvim_set_hl(0, "PrPanelAllResolved", { link = "DiagnosticOk", default = true })
end

-- ── Helpers ─────────────────────────────────────────────────

local function get_toplevel()
  if not _toplevel then
    _toplevel = vim.fn.system("git rev-parse --show-toplevel"):gsub("%s+$", "")
  end
  return _toplevel
end

local function rel_path(bufnr)
  local root = get_toplevel()
  local abs = vim.api.nvim_buf_get_name(bufnr)
  if root and abs:sub(1, #root) == root then
    return abs:sub(#root + 2)
  end
  return vim.fn.fnamemodify(abs, ":.")
end

local function get_repo_info()
  local out = vim.fn.system({ "gh", "repo", "view", "--json", "nameWithOwner", "-q", ".nameWithOwner" })
  if vim.v.shell_error ~= 0 then return nil, nil end
  local slug = out:gsub("%s+$", "")
  return slug:match("^(.+)/(.+)$")
end

local function time_ago(iso)
  if not iso then return "" end
  local y, mo, d, h, mi, s = iso:match("(%d+)-(%d+)-(%d+)T(%d+):(%d+):(%d+)")
  if not y then return iso end
  local t = os.time({
    year = tonumber(y), month = tonumber(mo), day = tonumber(d),
    hour = tonumber(h), min = tonumber(mi), sec = tonumber(s or 0),
  })
  local diff = math.abs(os.time() - t)
  if diff < 120 then return "just now"
  elseif diff < 3600 then return math.floor(diff / 60) .. "m ago"
  elseif diff < 86400 then return math.floor(diff / 3600) .. "h ago"
  elseif diff < 2592000 then return math.floor(diff / 86400) .. "d ago"
  else return string.format("%s-%s-%s", y, mo, d) end
end

-- ── Line mapping (old → new for LEFT-side comments) ────────

function M._build_line_map(filepath)
  if not M.merge_base then return {} end
  local diff = vim.fn.systemlist({ "git", "diff", M.merge_base, "--", filepath })
  local map = {}
  local old_ln, new_ln = 0, 0
  for _, line in ipairs(diff) do
    local os_str, _, ns_str = line:match("^@@ %-(%d+),?(%d*) %+(%d+),?(%d*) @@")
    if os_str then
      old_ln = tonumber(os_str) - 1
      new_ln = tonumber(ns_str) - 1
    elseif line:match("^diff") or line:match("^index") or line:match("^%-%-%-") or line:match("^%+%+%+") then
      -- skip diff headers
    elseif line:sub(1, 1) == " " then
      old_ln = old_ln + 1
      new_ln = new_ln + 1
      map[old_ln] = new_ln
    elseif line:sub(1, 1) == "-" then
      old_ln = old_ln + 1
      map[old_ln] = new_ln
    elseif line:sub(1, 1) == "+" then
      new_ln = new_ln + 1
    end
  end
  return map
end

function M._map_old_line(filepath, old_line)
  if not M.line_maps[filepath] then
    M.line_maps[filepath] = M._build_line_map(filepath)
  end
  return M.line_maps[filepath][old_line] or old_line
end

-- ── PR list (telescope) ─────────────────────────────────────

function M.list()
  if not pcall(require, "telescope") then
    vim.notify("Telescope required for PR picker", vim.log.levels.ERROR)
    return
  end

  vim.notify("Fetching PRs...")
  local output = vim.fn.system({
    "gh", "pr", "list",
    "--json", "number,title,author,headRefName,baseRefName,updatedAt,isDraft,body",
    "--limit", "30",
  })
  if vim.v.shell_error ~= 0 then
    vim.notify("Failed to fetch PRs: " .. output, vim.log.levels.ERROR)
    return
  end

  local prs = vim.fn.json_decode(output)
  if not prs or #prs == 0 then
    vim.notify("No open PRs", vim.log.levels.WARN)
    return
  end

  local pickers = require("telescope.pickers")
  local finders = require("telescope.finders")
  local conf = require("telescope.config").values
  local actions = require("telescope.actions")
  local action_state = require("telescope.actions.state")
  local previewers = require("telescope.previewers")

  pickers.new({}, {
    prompt_title = "Pull Requests",
    finder = finders.new_table({
      results = prs,
      entry_maker = function(pr)
        local draft = pr.isDraft and " [draft]" or ""
        local disp = string.format("#%-4d %-50s %s%s",
          pr.number, pr.title:sub(1, 50), pr.author.login, draft)
        return { value = pr, display = disp, ordinal = disp }
      end,
    }),
    sorter = conf.generic_sorter({}),
    previewer = previewers.new_buffer_previewer({
      title = "PR Details",
      define_preview = function(self, entry)
        local pr = entry.value
        local lines = {
          "# PR #" .. pr.number .. ": " .. pr.title,
          "",
          "**Author:** " .. pr.author.login,
          "**Base:** " .. pr.baseRefName .. " ← " .. pr.headRefName,
          "**Status:** " .. (pr.isDraft and "Draft" or "Open"),
          "**Updated:** " .. (pr.updatedAt or ""),
        }
        if pr.body and pr.body ~= "" then
          table.insert(lines, "")
          table.insert(lines, "---")
          table.insert(lines, "")
          for bl in pr.body:sub(1, 1500):gmatch("[^\n]*") do
            table.insert(lines, bl)
          end
        end
        vim.api.nvim_buf_set_lines(self.state.bufnr, 0, -1, false, lines)
        vim.bo[self.state.bufnr].filetype = "markdown"
      end,
    }),
    attach_mappings = function(prompt_bufnr)
      actions.select_default:replace(function()
        actions.close(prompt_bufnr)
        local sel = action_state.get_selected_entry()
        if sel then M.open(sel.value.number) end
      end)
      return true
    end,
  }):find()
end

-- ── PR open ─────────────────────────────────────────────────

function M.open(number)
  if M.active then
    vim.notify("PR review already active — close first with :PrClose or q", vim.log.levels.WARN)
    return
  end

  setup_highlights()
  _toplevel = nil

  local owner, repo = get_repo_info()
  if not owner then
    vim.notify("Not in a GitHub repo", vim.log.levels.ERROR)
    return
  end

  M.original_branch = vim.fn.system("git branch --show-current"):gsub("%s+$", "")

  local status = vim.fn.system("git status --porcelain")
  if status ~= "" then
    vim.notify("Stashing uncommitted changes...")
    vim.fn.system("git stash push -m 'pr-review-auto-stash'")
    M.stashed = true
  else
    M.stashed = false
  end

  vim.notify("Opening PR #" .. number .. "...")

  local pr_json = vim.fn.system({
    "gh", "pr", "view", tostring(number),
    "--json", "number,title,headRefName,baseRefName,headRefOid",
  })
  if vim.v.shell_error ~= 0 then
    vim.notify("Failed to fetch PR info", vim.log.levels.ERROR)
    M._restore_branch()
    return
  end

  local pr = vim.fn.json_decode(pr_json)
  M.pr_info = {
    number = pr.number, title = pr.title,
    base = pr.baseRefName, head = pr.headRefName,
    headOid = pr.headRefOid, owner = owner, repo = repo,
  }
  M.pr_number = number

  local co_out = vim.fn.system({ "gh", "pr", "checkout", tostring(number) })
  if vim.v.shell_error ~= 0 then
    vim.notify("Checkout failed: " .. co_out, vim.log.levels.ERROR)
    M._restore_branch()
    return
  end

  vim.fn.system({ "git", "fetch", "origin", pr.baseRefName })
  local mb = vim.fn.system({
    "git", "merge-base", "origin/" .. pr.baseRefName, "HEAD",
  }):gsub("%s+$", "")
  if vim.v.shell_error ~= 0 or mb == "" then
    vim.notify("Cannot compute merge base", vim.log.levels.ERROR)
    M._restore_branch()
    return
  end
  M.merge_base = mb
  M.active = true

  review.open(mb)

  if not review.active then
    vim.notify("No changes found in this PR", vim.log.levels.ERROR)
    M.active = false
    M._restore_branch()
    return
  end

  vim.keymap.set("n", "q", function() M.close() end, { desc = "Close PR review" })
  M._setup_keymaps()

  vim.api.nvim_create_autocmd("BufEnter", {
    group = M.augroup,
    callback = function(ev)
      if not M.active then return end
      vim.defer_fn(function()
        if M.active and vim.api.nvim_buf_is_valid(ev.buf) then
          M.render_buffer_comments(ev.buf, rel_path(ev.buf))
          M._update_panel_cursor()
        end
      end, 400)
    end,
  })

  vim.api.nvim_create_autocmd("VimLeavePre", {
    group = M.augroup,
    callback = function()
      if M.active then M._restore_branch() end
    end,
  })

  vim.defer_fn(function()
    M.fetch_threads(function()
      M.render_all_comments()
      vim.notify(string.format(
        " PR #%d: %s │ %d threads │ rp=files rc=comment rt=thread rR=refresh q=quit",
        number, pr.title, #M.threads
      ))
    end)
  end, 500)
end

-- ── Keymaps ─────────────────────────────────────────────────

function M._setup_keymaps()
  M._pr_maps = {
    { "n", "<leader>rc", function() M.add_comment() end, "PR: comment" },
    { "v", "<leader>rc", function() M.add_comment_visual() end, "PR: comment selection" },
    { "n", "<leader>rt", function() M.view_thread() end, "PR: view thread" },
    { "n", "<leader>rx", function() M.toggle_resolve() end, "PR: resolve/unresolve" },
    { "n", "<leader>rR", function() M.refresh() end, "PR: refresh" },
    { "n", "]t", function() M.next_thread() end, "PR: next thread" },
    { "n", "[t", function() M.prev_thread() end, "PR: prev thread" },
    { "n", "<leader>rp", function() M.toggle_panel() end, "PR: file panel" },
  }
  for _, m in ipairs(M._pr_maps) do
    vim.keymap.set(m[1], m[2], m[3], { desc = m[4] })
  end
end

function M._clear_keymaps()
  if M._pr_maps then
    for _, m in ipairs(M._pr_maps) do pcall(vim.keymap.del, m[1], m[2]) end
  end
end

-- ── Fetch threads (GraphQL) ─────────────────────────────────

function M.fetch_threads(callback)
  local query = string.format([[
{
  repository(owner: "%s", name: "%s") {
    pullRequest(number: %d) {
      reviewThreads(first: 100) {
        nodes {
          id
          isResolved
          isOutdated
          line
          originalLine
          startLine
          path
          diffSide
          comments(first: 50) {
            nodes {
              id
              databaseId
              body
              author { login }
              createdAt
            }
          }
        }
      }
    }
  }
}]], M.pr_info.owner, M.pr_info.repo, M.pr_number)

  local out = vim.fn.system({ "gh", "api", "graphql", "-f", "query=" .. query })
  if vim.v.shell_error ~= 0 then
    vim.notify("Failed to fetch threads", vim.log.levels.ERROR)
    if callback then callback() end
    return
  end

  local data = vim.fn.json_decode(out)
  local nodes = data
    and data.data and data.data.repository
    and data.data.repository.pullRequest
    and data.data.repository.pullRequest.reviewThreads
    and data.data.repository.pullRequest.reviewThreads.nodes or {}

  M.threads = nodes
  M.file_threads = {}
  M.line_maps = {}

  for _, t in ipairs(nodes) do
    if t.path then
      if not M.file_threads[t.path] then M.file_threads[t.path] = {} end
      local line
      if t.diffSide == "RIGHT" then
        line = type(t.line) == "number" and t.line or nil
      else
        line = type(t.line) == "number" and M._map_old_line(t.path, t.line) or nil
      end
      if type(line) == "number" and line >= 1 then
        table.insert(M.file_threads[t.path], {
          line = line,
          thread_id = t.id,
          is_resolved = t.isResolved,
          is_outdated = t.isOutdated,
          diff_side = t.diffSide,
          comments = t.comments and t.comments.nodes or {},
        })
      end
    end
  end

  if callback then callback() end
end

-- ── Render comments ─────────────────────────────────────────

function M.render_all_comments()
  for _, bufnr in ipairs(vim.api.nvim_list_bufs()) do
    if vim.api.nvim_buf_is_loaded(bufnr) then
      M.render_buffer_comments(bufnr, rel_path(bufnr))
    end
  end
end

function M.render_buffer_comments(bufnr, filepath)
  if not M.active or not filepath then return end
  vim.api.nvim_buf_clear_namespace(bufnr, M.ns, 0, -1)

  local threads = M.file_threads[filepath]
  if not threads then return end

  local line_count = vim.api.nvim_buf_line_count(bufnr)

  for _, thread in ipairs(threads) do
    local ln = thread.line
    if ln and ln >= 1 and ln <= line_count then
      local first = thread.comments[1]
      if first then
        local author = first.author and first.author.login or "unknown"
        local body = first.body:gsub("\n", " "):sub(1, 80)
        local count = #thread.comments
        local suffix = count > 1 and (" (+" .. (count - 1) .. " replies)") or ""
        local left_note = thread.diff_side == "LEFT" and " [base]" or ""

        local hl = thread.is_resolved and "PrCommentResolved" or "PrCommentVirt"
        local icon = thread.is_resolved and " ✓ " or " ◆ "

        vim.api.nvim_buf_set_extmark(bufnr, M.ns, ln - 1, 0, {
          virt_lines = { {
            { icon, hl },
            { "@" .. author .. left_note .. ": ", "PrCommentAuthor" },
            { body .. suffix, hl },
          } },
          virt_lines_above = false,
        })
      end
    end
  end
end

-- ── Floating input ──────────────────────────────────────────

function M._open_input(title, on_submit)
  local buf = vim.api.nvim_create_buf(false, true)
  vim.bo[buf].filetype = "markdown"
  vim.bo[buf].bufhidden = "wipe"

  local width = math.min(70, vim.o.columns - 4)
  local height = 8
  local row = math.floor((vim.o.lines - height) / 2)
  local col = math.floor((vim.o.columns - width) / 2)

  local win = vim.api.nvim_open_win(buf, true, {
    relative = "editor", row = row, col = col,
    width = width, height = height,
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

-- ── Add comment ─────────────────────────────────────────────

function M.add_comment(start_line, end_line)
  if not M.active then return end

  local bufnr = vim.api.nvim_get_current_buf()
  local filepath = rel_path(bufnr)
  local ln = end_line or vim.api.nvim_win_get_cursor(0)[1]
  local sl = start_line

  local label = (sl and sl ~= ln)
    and string.format("Comment %s:%d-%d", filepath, sl, ln)
    or string.format("Comment %s:%d", filepath, ln)

  M._open_input(label, function(body)
    local commit_id = vim.fn.system("git rev-parse HEAD"):gsub("%s+$", "")
    local args = {
      "gh", "api",
      string.format("repos/%s/%s/pulls/%d/comments", M.pr_info.owner, M.pr_info.repo, M.pr_number),
      "-f", "body=" .. body,
      "-f", "commit_id=" .. commit_id,
      "-f", "path=" .. filepath,
      "-F", "line=" .. tostring(ln),
      "-f", "side=RIGHT",
    }
    if sl and sl ~= ln then
      table.insert(args, "-F")
      table.insert(args, "start_line=" .. tostring(sl))
      table.insert(args, "-f")
      table.insert(args, "start_side=RIGHT")
    end

    vim.notify("Posting comment...")
    local result = vim.fn.system(args)
    if vim.v.shell_error ~= 0 then
      vim.notify("Failed: " .. result, vim.log.levels.ERROR)
    else
      vim.notify("Comment posted")
      M.refresh()
    end
  end)
end

function M.add_comment_visual()
  vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<Esc>", true, false, true), "x", false)
  vim.schedule(function()
    local sl = vim.fn.line("'<")
    local el = vim.fn.line("'>")
    M.add_comment(sl, el)
  end)
end

-- ── Reply ───────────────────────────────────────────────────

function M._reply_to_thread(thread)
  local first = thread.comments[1]
  if not first then return end

  M._open_input("Reply to @" .. (first.author and first.author.login or "?"), function(body)
    vim.notify("Posting reply...")
    local result = vim.fn.system({
      "gh", "api",
      string.format("repos/%s/%s/pulls/%d/comments", M.pr_info.owner, M.pr_info.repo, M.pr_number),
      "-f", "body=" .. body,
      "-F", "in_reply_to=" .. tostring(first.databaseId),
    })
    if vim.v.shell_error ~= 0 then
      vim.notify("Failed: " .. result, vim.log.levels.ERROR)
    else
      vim.notify("Reply posted")
      M.refresh()
    end
  end)
end

-- ── Thread viewer ───────────────────────────────────────────

function M.view_thread()
  if not M.active then return end
  local thread = M._thread_at_cursor()
  if not thread then
    vim.notify("No thread at cursor — move to a line with ◆", vim.log.levels.INFO)
    return
  end
  M._open_thread_window(thread)
end

function M._thread_at_cursor()
  local bufnr = vim.api.nvim_get_current_buf()
  local ln = vim.api.nvim_win_get_cursor(0)[1]
  local fp = rel_path(bufnr)
  local threads = M.file_threads[fp]
  if not threads then return nil end
  for _, t in ipairs(threads) do
    if t.line == ln then return t end
  end
  return nil
end

function M._open_thread_window(thread)
  local comments = thread.comments or {}
  local lines = {}
  local hls = {}

  local status = thread.is_resolved and "  RESOLVED" or ""
  local outdated = thread.is_outdated and "  OUTDATED" or ""
  table.insert(lines, " Thread" .. status .. outdated)
  table.insert(hls, { #lines - 1, "PrThreadTitle" })
  table.insert(lines, " " .. string.rep("─", 50))
  table.insert(hls, { #lines - 1, "PrThreadSep" })
  table.insert(lines, "")

  for i, c in ipairs(comments) do
    local author = c.author and c.author.login or "unknown"
    local ago = time_ago(c.createdAt)
    table.insert(lines, " @" .. author .. "  " .. ago)
    table.insert(hls, { #lines - 1, "PrThreadAuthor" })
    for bl in (c.body or ""):gmatch("[^\n]*") do
      table.insert(lines, "  " .. bl)
    end
    if i < #comments then
      table.insert(lines, "")
      table.insert(lines, " " .. string.rep("·", 42))
      table.insert(hls, { #lines - 1, "PrThreadSep" })
      table.insert(lines, "")
    end
  end

  table.insert(lines, "")
  table.insert(lines, " " .. string.rep("─", 50))
  table.insert(hls, { #lines - 1, "PrThreadSep" })
  local resolve_label = thread.is_resolved and "unresolve" or "resolve"
  table.insert(lines, " r reply   x " .. resolve_label .. "   q close")

  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  vim.bo[buf].modifiable = false
  vim.bo[buf].filetype = "markdown"
  vim.bo[buf].bufhidden = "wipe"

  local hl_ns = vim.api.nvim_create_namespace("pr_thread_hl")
  for _, h in ipairs(hls) do
    vim.api.nvim_buf_add_highlight(buf, hl_ns, h[2], h[1], 0, -1)
  end

  local width = math.min(62, vim.o.columns - 4)
  local height = math.min(#lines, math.floor(vim.o.lines * 0.6))
  local row = math.floor((vim.o.lines - height) / 2)
  local col = math.floor((vim.o.columns - width) / 2)

  local win = vim.api.nvim_open_win(buf, true, {
    relative = "editor", row = row, col = col,
    width = width, height = height,
    style = "minimal", border = "rounded",
    title = " PR Thread ", title_pos = "center",
  })

  vim.wo[win].wrap = true
  vim.wo[win].linebreak = true

  local function close()
    if vim.api.nvim_win_is_valid(win) then vim.api.nvim_win_close(win, true) end
  end

  vim.keymap.set("n", "q", close, { buffer = buf })
  vim.keymap.set("n", "<Esc>", close, { buffer = buf })
  vim.keymap.set("n", "r", function()
    close()
    M._reply_to_thread(thread)
  end, { buffer = buf })
  vim.keymap.set("n", "x", function()
    close()
    M._toggle_resolve_thread(thread)
  end, { buffer = buf })
end

-- ── Resolve / unresolve ─────────────────────────────────────

function M.toggle_resolve()
  local thread = M._thread_at_cursor()
  if not thread then
    vim.notify("No thread at cursor", vim.log.levels.INFO)
    return
  end
  M._toggle_resolve_thread(thread)
end

function M._toggle_resolve_thread(thread)
  local mutation = thread.is_resolved and "unresolveReviewThread" or "resolveReviewThread"
  local query = string.format(
    'mutation { %s(input: {threadId: "%s"}) { thread { isResolved } } }',
    mutation, thread.thread_id
  )

  vim.notify(thread.is_resolved and "Unresolving..." or "Resolving...")
  local out = vim.fn.system({ "gh", "api", "graphql", "-f", "query=" .. query })
  if vim.v.shell_error ~= 0 then
    vim.notify("Failed: " .. out, vim.log.levels.ERROR)
  else
    vim.notify(thread.is_resolved and "Thread unresolved" or "Thread resolved")
    M.refresh()
  end
end

-- ── Navigation ──────────────────────────────────────────────

function M.next_thread() M._jump_thread(1) end
function M.prev_thread() M._jump_thread(-1) end

function M._jump_thread(dir)
  if not M.active then return end
  local bufnr = vim.api.nvim_get_current_buf()
  local cur = vim.api.nvim_win_get_cursor(0)[1]
  local fp = rel_path(bufnr)
  local threads = M.file_threads[fp]
  if not threads or #threads == 0 then return end

  local sorted = {}
  for _, t in ipairs(threads) do table.insert(sorted, t.line) end
  table.sort(sorted)

  if dir > 0 then
    for _, ln in ipairs(sorted) do
      if ln > cur then
        vim.api.nvim_win_set_cursor(0, { ln, 0 })
        return
      end
    end
    vim.api.nvim_win_set_cursor(0, { sorted[1], 0 })
  else
    for i = #sorted, 1, -1 do
      if sorted[i] < cur then
        vim.api.nvim_win_set_cursor(0, { sorted[i], 0 })
        return
      end
    end
    vim.api.nvim_win_set_cursor(0, { sorted[#sorted], 0 })
  end
end

-- ── File panel ───────────────────────────────────────────────

function M.toggle_panel()
  if not M.active then return end
  if M.panel_win and vim.api.nvim_win_is_valid(M.panel_win) then
    vim.api.nvim_win_close(M.panel_win, true)
    M.panel_win = nil
    M.panel_buf = nil
    return
  end
  M._open_panel()
end

-- Compute +/- stats per file (cached)
function M._ensure_file_stats()
  if next(M.file_stats) then return end
  if not M.merge_base then return end
  local raw = vim.fn.systemlist({ "git", "diff", "--numstat", M.merge_base })
  for _, line in ipairs(raw) do
    local add, del, path = line:match("^(%d+)%s+(%d+)%s+(.+)$")
    if path then
      M.file_stats[path] = { add = tonumber(add) or 0, del = tonumber(del) or 0 }
    elseif line:match("^%-") then
      local p = line:match("^%-[%s%-]+(.+)$")
      if p then M.file_stats[p] = { add = 0, del = 0, binary = true } end
    end
  end
end

-- Get devicon for a file (fallback to plain icon)
local function file_icon(filepath)
  local ok, devicons = pcall(require, "nvim-web-devicons")
  if ok then
    local name = vim.fn.fnamemodify(filepath, ":t")
    local ext = vim.fn.fnamemodify(filepath, ":e")
    local icon, hl = devicons.get_icon(name, ext, { default = true })
    return icon or "", hl
  end
  return "", nil
end

-- Count threads per file: { total, unresolved, resolved }
function M._file_thread_counts(filepath)
  local threads = M.file_threads[filepath]
  if not threads then return 0, 0, 0 end
  local total, unresolved, resolved = 0, 0, 0
  for _, t in ipairs(threads) do
    total = total + 1
    if t.is_resolved then resolved = resolved + 1 else unresolved = unresolved + 1 end
  end
  return total, unresolved, resolved
end

-- Build directory-grouped tree structure
function M._build_file_tree()
  local files = review.files or {}
  local dirs = {}
  local dir_order = {}

  for _, f in ipairs(files) do
    local dir = vim.fn.fnamemodify(f, ":h")
    if dir == "." then dir = "" end
    if not dirs[dir] then
      dirs[dir] = {}
      table.insert(dir_order, dir)
    end
    table.insert(dirs[dir], f)
  end

  return dirs, dir_order
end

function M._open_panel()
  local files = review.files or {}
  if #files == 0 then
    vim.notify("No changed files", vim.log.levels.WARN)
    return
  end

  M._ensure_file_stats()

  local buf = vim.api.nvim_create_buf(false, true)
  M.panel_buf = buf
  vim.bo[buf].buftype = "nofile"
  vim.bo[buf].bufhidden = "wipe"
  vim.bo[buf].swapfile = false
  vim.bo[buf].filetype = "prpanel"

  vim.cmd("topleft 42vsplit")
  M.panel_win = vim.api.nvim_get_current_win()
  vim.api.nvim_win_set_buf(M.panel_win, buf)

  vim.wo[M.panel_win].number = false
  vim.wo[M.panel_win].relativenumber = false
  vim.wo[M.panel_win].signcolumn = "no"
  vim.wo[M.panel_win].foldcolumn = "0"
  vim.wo[M.panel_win].winfixwidth = true
  vim.wo[M.panel_win].wrap = false
  vim.wo[M.panel_win].spell = false
  vim.wo[M.panel_win].cursorline = true

  M._render_panel()

  -- Panel keymaps
  vim.keymap.set("n", "<CR>", function()
    local file = M._panel_file_at_cursor()
    if file then
      for _, w in ipairs(vim.api.nvim_list_wins()) do
        if w ~= M.panel_win and vim.api.nvim_win_is_valid(w) then
          vim.api.nvim_set_current_win(w)
          break
        end
      end
      vim.cmd("edit " .. vim.fn.fnameescape(file))
    end
  end, { buffer = buf, desc = "Open file" })

  vim.keymap.set("n", "m", function()
    local file = M._panel_file_at_cursor()
    if file then
      M.reviewed[file] = not M.reviewed[file] or nil
      M._render_panel()
    end
  end, { buffer = buf, desc = "Toggle reviewed" })

  vim.keymap.set("n", "o", function()
    local dir = M._panel_dir_at_cursor()
    if dir then
      M.panel_collapsed[dir] = not M.panel_collapsed[dir]
      M._render_panel()
    end
  end, { buffer = buf, desc = "Toggle folder" })

  vim.keymap.set("n", "q", function()
    M.toggle_panel()
  end, { buffer = buf, desc = "Close panel" })

  -- Move cursor to first file line
  pcall(vim.api.nvim_win_set_cursor, M.panel_win, { (M._first_file_row or 4) + 1, 0 })
end

function M._render_panel()
  if not M.panel_buf or not vim.api.nvim_buf_is_valid(M.panel_buf) then return end

  local files = review.files or {}
  local reviewed_count = 0
  for _, f in ipairs(files) do
    if M.reviewed[f] then reviewed_count = reviewed_count + 1 end
  end

  local cur_file = rel_path(vim.api.nvim_get_current_buf())
  local lines = {}
  local hls = {}       -- { row, hl_group, col_start, col_end }
  M._panel_row_map = {} -- row → filepath (only for file rows)
  M._panel_dir_map = {} -- row → dir (only for dir rows)
  M._first_file_row = nil

  local function hl(row, group, cs, ce)
    table.insert(hls, { row, group, cs or 0, ce or -1 })
  end

  -- Header
  local title = M.pr_info and ("PR #" .. M.pr_info.number) or "PR Review"
  if M.pr_info and M.pr_info.title then
    title = title .. ": " .. M.pr_info.title:sub(1, 28)
  end
  table.insert(lines, " " .. title)
  hl(#lines - 1, "PrPanelTitle")
  table.insert(lines, " " .. string.rep("─", 39))
  hl(#lines - 1, "PrPanelSep")
  table.insert(lines, "")

  -- Build directory tree
  local dirs, dir_order = M._build_file_tree()

  for _, dir in ipairs(dir_order) do
    local dir_files = dirs[dir]
    local collapsed = M.panel_collapsed[dir]

    -- Directory header (skip for root-level files)
    if dir ~= "" then
      local arrow = collapsed and " ▸ " or " ▾ "
      local row = #lines
      table.insert(lines, arrow .. dir .. "/")
      M._panel_dir_map[row + 1] = dir
      hl(row, "PrPanelDirArrow", 0, #arrow)
      hl(row, "PrPanelDir", #arrow, -1)
    end

    if not collapsed then
      for _, f in ipairs(dir_files) do
        local fname = dir ~= "" and vim.fn.fnamemodify(f, ":t") or f
        local is_reviewed = M.reviewed[f]
        local is_current = (f == cur_file)
        local stats = M.file_stats[f] or { add = 0, del = 0 }
        local total_threads, unresolved, resolved = M._file_thread_counts(f)
        local icon, icon_hl = file_icon(f)

        -- Status icon
        local status
        if is_reviewed and unresolved == 0 then
          status = " ✓"
        elseif unresolved > 0 then
          status = " ●"
        elseif is_reviewed then
          status = " ◐"
        else
          status = "  "
        end

        -- Indent under directory
        local indent = dir ~= "" and "   " or " "

        -- Build line: status icon filename  +N -N  comments
        local stat_str = ""
        if stats.binary then
          stat_str = " bin"
        elseif stats.add > 0 or stats.del > 0 then
          stat_str = string.format(" +%d -%d", stats.add, stats.del)
        end

        local comment_str = ""
        if total_threads > 0 then
          if unresolved > 0 then
            comment_str = string.format("  %d", unresolved)
          elseif resolved > 0 then
            comment_str = string.format("  %d ✓", resolved)
          end
        end

        local line_text = status .. indent .. icon .. " " .. fname
        local padded = line_text .. string.rep(" ", math.max(1, 26 - #line_text))
        local full = padded .. stat_str .. comment_str

        local row = #lines
        table.insert(lines, full)
        M._panel_row_map[row + 1] = f
        if not M._first_file_row then M._first_file_row = row end

        -- Highlights
        if is_current then
          hl(row, "PrPanelCurrent")
        end

        -- Status icon highlight
        if is_reviewed and unresolved == 0 then
          hl(row, "PrPanelReviewed", 0, #status)
        elseif unresolved > 0 then
          hl(row, "PrPanelUnresolved", 0, #status)
        end

        -- Devicon highlight
        if icon_hl then
          local icon_start = #status + #indent
          hl(row, icon_hl, icon_start, icon_start + #icon)
        end

        -- Stat highlights
        if stat_str ~= "" then
          local stat_start = #padded
          local plus_end = stat_start + stat_str:find("-") - 1
          hl(row, "PrPanelAdd", stat_start, plus_end)
          hl(row, "PrPanelDel", plus_end, stat_start + #stat_str)
        end

        -- Comment badge highlight
        if comment_str ~= "" then
          local badge_start = #padded + #stat_str
          if unresolved > 0 then
            hl(row, "PrPanelUnresolved", badge_start, badge_start + #comment_str)
          else
            hl(row, "PrPanelAllResolved", badge_start, badge_start + #comment_str)
          end
        end

        -- Dim reviewed files (filename portion only)
        if is_reviewed and not is_current then
          hl(row, "PrPanelReviewed", #status + #indent, #status + #indent + #icon + 1 + #fname)
        end
      end
    end
  end

  -- Footer
  table.insert(lines, "")
  local sep_row = #lines
  table.insert(lines, " " .. string.rep("─", 39))
  hl(sep_row, "PrPanelSep")

  local counter = string.format(" %d/%d reviewed", reviewed_count, #files)
  local counter_row = #lines
  table.insert(lines, counter)
  hl(counter_row, "PrPanelCounter")

  -- Legend
  table.insert(lines, "")
  local legend_row = #lines
  table.insert(lines, " ✓ done  ● unresolved  ◐ partial")
  hl(legend_row, "PrPanelSep")
  local keys_row = #lines
  table.insert(lines, " Enter open  m mark  o fold  q close")
  hl(keys_row, "PrPanelSep")

  vim.bo[M.panel_buf].modifiable = true
  vim.api.nvim_buf_set_lines(M.panel_buf, 0, -1, false, lines)
  vim.bo[M.panel_buf].modifiable = false

  local ns = vim.api.nvim_create_namespace("pr_panel_hl")
  vim.api.nvim_buf_clear_namespace(M.panel_buf, ns, 0, -1)
  for _, h in ipairs(hls) do
    vim.api.nvim_buf_add_highlight(M.panel_buf, ns, h[2], h[1], h[3], h[4])
  end
end

function M._panel_file_at_cursor()
  if not M.panel_win or not vim.api.nvim_win_is_valid(M.panel_win) then return nil end
  local row = vim.api.nvim_win_get_cursor(M.panel_win)[1]
  return M._panel_row_map and M._panel_row_map[row] or nil
end

function M._panel_dir_at_cursor()
  if not M.panel_win or not vim.api.nvim_win_is_valid(M.panel_win) then return nil end
  local row = vim.api.nvim_win_get_cursor(M.panel_win)[1]
  return M._panel_dir_map and M._panel_dir_map[row] or nil
end

function M._update_panel_cursor()
  if not M.panel_buf or not vim.api.nvim_buf_is_valid(M.panel_buf) then return end
  M._render_panel()
end

function M._close_panel()
  if M.panel_win and vim.api.nvim_win_is_valid(M.panel_win) then
    vim.api.nvim_win_close(M.panel_win, true)
  end
  M.panel_win = nil
  M.panel_buf = nil
end

-- ── Refresh ─────────────────────────────────────────────────

function M.refresh()
  if not M.active then return end
  M.fetch_threads(function()
    M.render_all_comments()
    M._update_panel_cursor()
    vim.notify("Refreshed (" .. #M.threads .. " threads)")
  end)
end

-- ── Close ───────────────────────────────────────────────────

function M.close()
  if not M.active then return end
  M.active = false

  vim.api.nvim_clear_autocmds({ group = M.augroup })

  for _, bufnr in ipairs(vim.api.nvim_list_bufs()) do
    if vim.api.nvim_buf_is_valid(bufnr) then
      vim.api.nvim_buf_clear_namespace(bufnr, M.ns, 0, -1)
    end
  end

  M._close_panel()
  M._clear_keymaps()
  review.close()
  M._restore_branch()

  M.pr_number = nil
  M.pr_info = nil
  M.threads = {}
  M.file_threads = {}
  M.line_maps = {}
  M.merge_base = nil
  M.reviewed = {}
  M.file_stats = {}
  M.panel_collapsed = {}

  vim.notify("PR review closed")
end

function M._restore_branch()
  if M.original_branch and M.original_branch ~= "" then
    vim.fn.system({ "git", "checkout", M.original_branch })
    if M.stashed then
      vim.fn.system("git stash pop")
      M.stashed = false
    end
  end
  M.original_branch = nil
  _toplevel = nil
end

-- ── Commands ────────────────────────────────────────────────

vim.api.nvim_create_user_command("PrReview", function(opts)
  local num = tonumber(opts.args)
  if num then M.open(num) else M.list() end
end, { nargs = "?" })

vim.api.nvim_create_user_command("PrRefresh", function() M.refresh() end, {})
vim.api.nvim_create_user_command("PrClose", function() M.close() end, {})

return M
