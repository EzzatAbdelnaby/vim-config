-- ~/.config/nvim/lua/config/autocmds.lua
local augroup = vim.api.nvim_create_augroup("MyPythonConfig", { clear = true })

-- Auto-format Python files on save
vim.api.nvim_create_autocmd("BufWritePre", {
  pattern = "*.py",
  callback = function()
    -- Use conform.nvim if available
    if package.loaded["conform"] then
      require("conform").format({ bufnr = 0 })
    else
      vim.lsp.buf.format({ async = false })
    end
  end,
  group = augroup,
})

-- Set indentation for Python files
vim.api.nvim_create_autocmd("FileType", {
  pattern = "python",
  callback = function()
    vim.opt_local.expandtab = true
    vim.opt_local.shiftwidth = 4
    vim.opt_local.tabstop = 4
    vim.opt_local.softtabstop = 4
  end,
  group = augroup,
})

-- Automatically activate virtual environment if found
vim.api.nvim_create_autocmd("VimEnter", {
  pattern = "*",
  callback = function()
    if vim.fn.filereadable(".venv/bin/python") == 1 or vim.fn.filereadable("venv/bin/python") == 1 then
      if package.loaded["venv-selector"] then
        vim.defer_fn(function()
          require("venv-selector").retrieve_from_cache()
        end, 100)
      end
    end
  end,
  group = augroup,
})

-- Auto close document view when it's the last window
vim.api.nvim_create_autocmd("BufEnter", {
  pattern = "*",
  callback = function()
    if vim.bo.filetype == "help" or vim.bo.filetype == "startuptime" or vim.bo.filetype == "qf" then
      vim.cmd([[if winnr('$') == 1 | q | endif]])
    end
  end,
  group = augroup,
})

-- Highlight yanked text
vim.api.nvim_create_autocmd("TextYankPost", {
  pattern = "*",
  callback = function()
    vim.highlight.on_yank({ higroup = "IncSearch", timeout = 300 })
  end,
  group = augroup,
})
