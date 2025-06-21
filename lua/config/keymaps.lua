local map = vim.keymap.set
local opts = { noremap = true, silent = true }

-- Basic Keymaps
map("i", "jk", "<Esc>", opts) -- Escape insert mode
map("n", "<leader>w", ":w<CR>", opts) -- Save file
map("n", "<leader>q", ":q<CR>", opts) -- Quit
map("n", "<leader>x", ":x<CR>", opts) -- Save & quit
map("n", "<leader>h", ":nohlsearch<CR>", opts) -- Clear search highlight

-- Navigation
map("n", "<C-d>", "<C-d>zz", opts) -- Scroll down half page, center
map("n", "<C-u>", "<C-u>zz", opts) -- Scroll up half page, center
map("n", "n", "nzzzv", opts) -- Keep search results centered
map("n", "N", "Nzzzv", opts)

-- Window Management
map("n", "<leader>sv", ":vsplit<CR>", opts) -- Split window vertically
map("n", "<leader>sh", ":split<CR>", opts) -- Split window horizontally
map("n", "<leader>se", "<C-w>=", opts) -- Equalize window sizes
map("n", "<leader>sx", ":close<CR>", opts) -- Close window

-- Buffer Navigation
map("n", "<leader>bn", ":bnext<CR>", opts) -- Next buffer
map("n", "<leader>bp", ":bprevious<CR>", opts) -- Previous buffer
map("n", "<leader>bd", ":bd<CR>", opts) -- Delete buffer

-- Tabs
map("n", "<leader>to", ":tabnew<CR>", opts) -- Open new tab
map("n", "<leader>tx", ":tabclose<CR>", opts) -- Close tab
map("n", "<leader>tn", ":tabnext<CR>", opts) -- Next tab
map("n", "<leader>tp", ":tabprevious<CR>", opts) -- Previous tab

-- Telescope
map("n", "<leader>ff", ":Telescope find_files<CR>", opts) -- Find files
map("n", "<leader>fg", function()
  -- Ensure telescope is loaded
  local telescope_ok, telescope = pcall(require, "telescope.builtin")
  if telescope_ok then
    telescope.live_grep()
  else
    vim.notify("Telescope not available", vim.log.levels.ERROR)
  end
end, opts)
map("n", "<leader>fb", function()
  require("telescope.builtin").buffers()
end, opts) -- List buffers
map("n", "<leader>fh", ":Telescope help_tags<CR>", opts) -- Help tags

-- LSP - Fix keybindings to work with lazy loading
map("n", "gd", function()
  vim.lsp.buf.definition()
end, opts)
map("n", "gr", function()
  vim.lsp.buf.references()
end, opts)
map("n", "K", function()
  vim.lsp.buf.hover()
end, opts)
map("n", "<leader>rn", function()
  vim.lsp.buf.rename()
end, opts)
map("n", "<leader>ca", function()
  vim.lsp.buf.code_action()
end, opts)

-- Git
map("n", "<leader>gs", ":Gitsigns stage_hunk<CR>", opts)
map("n", "<leader>gu", ":Gitsigns undo_stage_hunk<CR>", opts)
map("n", "<leader>gp", ":Gitsigns preview_hunk<CR>", opts)
map("n", "<leader>gb", ":Telescope git_branches<CR>", opts)

-- Terminal
map("n", "<leader>tt", ":ToggleTerm<CR>", opts) -- Open terminal
map("t", "<Esc>", "<C-\\><C-n>", opts) -- Exit terminal mode

-- Formatting
map("n", "<leader>fm", ":lua vim.lsp.buf.format()<CR>", opts)

-- Commenting
map("n", "<leader>/", ":lua require('Comment.api').toggle.linewise.current()<CR>", opts)
map("v", "<leader>/", ":lua require('Comment.api').toggle.linewise(vim.fn.visualmode())<CR>", opts)

-- Quickfix List
map("n", "<leader>cn", ":cnext<CR>", opts)
map("n", "<leader>cp", ":cprevious<CR>", opts)
map("n", "<leader>cc", ":cclose<CR>", opts)

-- FIX: Use function() wrappers for UFO commands to lazy-load them
map("n", "zR", function()
  require("ufo").openAllFolds()
end, opts) -- Open all folds
map("n", "zM", function()
  require("ufo").closeAllFolds()
end, opts) -- Close all folds
map("n", "zr", function()
  require("ufo").openFoldsExceptKinds()
end, opts) -- Open folds except small ones
map("n", "zm", function()
  require("ufo").closeFoldsWith()
end, opts) -- Close folds of a certain level
