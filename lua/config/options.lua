-- Neovim Options Configuration
local opt = vim.opt
local g = vim.g

-- Leader key
g.mapleader = " "
g.maplocalleader = "\\"

-- Line numbers
opt.number = true
opt.relativenumber = true

-- Tabs & Indentation
opt.tabstop = 2
opt.shiftwidth = 2
opt.expandtab = true
opt.autoindent = true
opt.smartindent = true

-- Line wrapping
opt.wrap = false

-- Search settings
opt.ignorecase = true
opt.smartcase = true
opt.hlsearch = true
opt.incsearch = true

-- Appearance
opt.termguicolors = true
opt.background = "dark"
opt.signcolumn = "yes"
opt.cursorline = true
opt.colorcolumn = "100"

-- Backspace
opt.backspace = "indent,eol,start"

-- Clipboard
opt.clipboard:append("unnamedplus")

-- Split windows
opt.splitright = true
opt.splitbelow = true

-- Swapfile & Backup
opt.swapfile = false
opt.backup = false
opt.undofile = true
opt.undodir = vim.fn.expand("~/.vim/undodir")

-- Scroll
opt.scrolloff = 8
opt.sidescrolloff = 8

-- Performance
opt.updatetime = 250
opt.timeoutlen = 300

-- Completion
opt.completeopt = "menu,menuone,noselect"

-- File encoding
opt.fileencoding = "utf-8"

-- Mouse
opt.mouse = "a"

-- Blinking cursor
opt.guicursor = "n-v-c:block-blinkon500-blinkoff500,i-ci-ve:ver25-blinkon500-blinkoff500,r-cr:hor20-blinkon500-blinkoff500"

-- Folding
opt.foldmethod = "expr"
opt.foldexpr = "nvim_treesitter#foldexpr()"
opt.foldenable = false
opt.foldlevel = 99

-- Miscellaneous
opt.iskeyword:append("-")
opt.hidden = true
opt.showmode = false

-- Auto-reload files when changed externally
opt.autoread = true

-- Highlight yanked text
vim.api.nvim_create_autocmd("TextYankPost", {
  desc = "Highlight when yanking text",
  group = vim.api.nvim_create_augroup("highlight-yank", { clear = true }),
  callback = function()
    vim.highlight.on_yank({ higroup = "IncSearch", timeout = 200 })
  end,
})

-- Auto-reload files when changed externally (by Claude, git, etc.)
vim.api.nvim_create_autocmd({ "FocusGained", "BufEnter", "CursorHold", "CursorHoldI" }, {
  desc = "Check for external file changes",
  group = vim.api.nvim_create_augroup("auto-reload", { clear = true }),
  callback = function()
    if vim.fn.getcmdwintype() == "" then
      vim.cmd("checktime")
    end
  end,
})

-- Notify when file is reloaded
vim.api.nvim_create_autocmd("FileChangedShellPost", {
  desc = "Notify when file is changed externally",
  group = vim.api.nvim_create_augroup("auto-reload-notify", { clear = true }),
  callback = function()
    vim.notify("File changed on disk. Buffer reloaded.", vim.log.levels.INFO)
  end,
})
