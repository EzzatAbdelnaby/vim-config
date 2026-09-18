-- Custom unified code review mode
-- Single pane, full file, GitHub-style red/green highlights
-- Usage: :ReviewOpen main   (or any branch/commit)
--        :ReviewClose

local M = {}

M.active = false
M.files = {}
M.base = "HEAD"

function M.open(base)
  base = base or "HEAD"
  M.base = base

  -- Get changed files (tracked + untracked)
  local output = vim.fn.systemlist("git diff --name-only " .. vim.fn.shellescape(base))
  if vim.v.shell_error ~= 0 then output = {} end
  local untracked = vim.fn.systemlist("git ls-files --others --exclude-standard")
  if vim.v.shell_error == 0 then
    vim.list_extend(output, untracked)
  end
  if #output == 0 then
    vim.notify("No changes found against " .. base, vim.log.levels.WARN)
    return
  end

  M.files = vim.tbl_filter(function(f) return f ~= "" end, output)
  if #M.files == 0 then
    vim.notify("No changes found", vim.log.levels.WARN)
    return
  end

  M.active = true

  -- Save existing highlights so we can restore them
  M.saved_hl = {}
  local hl_groups = {
    "GitSignsAddLn", "GitSignsChangeLn", "GitSignsDeleteLn",
    "GitSignsDeleteVirtLn", "GitSignsDeleteVirtLnInline",
    "GitSignsAddInline", "GitSignsDeleteInline", "GitSignsChangeInline",
  }
  for _, name in ipairs(hl_groups) do
    M.saved_hl[name] = vim.api.nvim_get_hl(0, { name = name })
  end

  -- GitHub-style review highlights
  -- Added lines: green background
  vim.api.nvim_set_hl(0, "GitSignsAddLn", { bg = "#1a3024" })
  vim.api.nvim_set_hl(0, "GitSignsChangeLn", { bg = "#1a3024" })
  -- Deleted lines: red background
  vim.api.nvim_set_hl(0, "GitSignsDeleteLn", { bg = "#301a1e" })
  vim.api.nvim_set_hl(0, "GitSignsDeleteVirtLn", { bg = "#301a1e", fg = "#e06c75" })
  vim.api.nvim_set_hl(0, "GitSignsDeleteVirtLnInline", { bg = "#4d2030", fg = "#e06c75" })
  -- Word-level: stronger color on the exact changed text
  vim.api.nvim_set_hl(0, "GitSignsAddInline", { bg = "#2a5034" })
  vim.api.nvim_set_hl(0, "GitSignsDeleteInline", { bg = "#4d2030" })
  vim.api.nvim_set_hl(0, "GitSignsChangeInline", { bg = "#2a5034" })

  -- Open first changed file
  vim.cmd("edit " .. vim.fn.fnameescape(M.files[1]))

  -- Load remaining files as hidden buffers
  for i = 2, #M.files do
    vim.cmd("badd " .. vim.fn.fnameescape(M.files[i]))
  end

  -- Wait for gitsigns to attach then configure review display
  vim.defer_fn(function()
    local ok, gs = pcall(require, "gitsigns")
    if not ok then
      vim.notify("gitsigns not found", vim.log.levels.ERROR)
      return
    end

    -- Compare against the specified base
    gs.change_base(base, true)

    -- Show deleted lines inline (red virtual text)
    gs.toggle_deleted(true)

    -- Highlight added/changed lines with background color
    gs.toggle_linehl(true)

    -- Show word-level changes within lines
    gs.toggle_word_diff(true)

    -- Jump to first hunk
    vim.schedule(function()
      pcall(gs.next_hunk)
    end)
  end, 300)

  -- Review keymaps
  vim.keymap.set("n", "<leader>rf", function() M.pick_file() end, { desc = "Review: pick file" })
  vim.keymap.set("n", "q", function() M.close() end, { desc = "Close review" })

  vim.notify(
    string.format(
      " Review: %d files vs %s │ Tab/S-Tab=files  ]c/[c=hunks  <leader>rf=pick  q=quit",
      #M.files, base
    )
  )
end

function M.close()
  if not M.active then return end
  M.active = false

  local ok, gs = pcall(require, "gitsigns")
  if ok then
    gs.toggle_deleted(false)
    gs.toggle_linehl(false)
    gs.toggle_word_diff(false)
    gs.change_base(nil, true)
  end

  -- Restore original highlights
  if M.saved_hl then
    for name, hl in pairs(M.saved_hl) do
      vim.api.nvim_set_hl(0, name, hl)
    end
    M.saved_hl = nil
  end

  -- Wipe review buffers
  for _, f in ipairs(M.files) do
    local buf = vim.fn.bufnr(f)
    if buf ~= -1 then
      pcall(vim.api.nvim_buf_delete, buf, { force = true })
    end
  end

  M.files = {}
  vim.cmd("enew")

  -- Remove review keymaps
  pcall(vim.keymap.del, "n", "<leader>rf")
  pcall(vim.keymap.del, "n", "q")

  vim.notify("Review closed")
end

function M.pick_file()
  -- Use telescope if available, otherwise vim.ui.select
  local has_telescope, builtin = pcall(require, "telescope.builtin")
  if has_telescope then
    local pickers = require("telescope.pickers")
    local finders = require("telescope.finders")
    local conf = require("telescope.config").values
    local actions = require("telescope.actions")
    local action_state = require("telescope.actions.state")

    pickers.new({}, {
      prompt_title = "Changed Files (" .. M.base .. ")",
      finder = finders.new_table({ results = M.files }),
      sorter = conf.generic_sorter({}),
      attach_mappings = function(prompt_bufnr)
        actions.select_default:replace(function()
          actions.close(prompt_bufnr)
          local selection = action_state.get_selected_entry()
          if selection then
            vim.cmd("edit " .. vim.fn.fnameescape(selection[1]))
          end
        end)
        return true
      end,
    }):find()
  else
    vim.ui.select(M.files, { prompt = "Changed files:" }, function(choice)
      if choice then
        vim.cmd("edit " .. vim.fn.fnameescape(choice))
      end
    end)
  end
end

-- Commands
vim.api.nvim_create_user_command("ReviewOpen", function(opts)
  M.open(opts.args ~= "" and opts.args or nil)
end, { nargs = "?" })

vim.api.nvim_create_user_command("ReviewClose", function()
  M.close()
end, {})

return M
