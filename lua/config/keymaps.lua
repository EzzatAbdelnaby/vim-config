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
map("n", "<leader>fg", ":Telescope live_grep<CR>", opts) -- Live grep
map("n", "<leader>fb", ":Telescope buffers<CR>", opts) -- List buffers
map("n", "<leader>fh", ":Telescope help_tags<CR>", opts) -- Help tags

-- LSP
map("n", "gd", "vim.lsp.buf.definition", opts)
map("n", "gr", "vim.lsp.buf.references", opts)
map("n", "K", "vim.lsp.buf.hover", opts)
map("n", "<leader>rn", "vim.lsp.buf.rename", opts)
map("n", "<leader>ca", "vim.lsp.buf.code_action", opts)

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

map("n", "zR", require("ufo").openAllFolds, opts) -- Open all folds
map("n", "zM", require("ufo").closeAllFolds, opts) -- Close all folds
map("n", "zr", require("ufo").openFoldsExceptKinds, opts) -- Open folds except small ones
map("n", "zm", require("ufo").closeFoldsWith, opts) -- Close folds of a certain level
