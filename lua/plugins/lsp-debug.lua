return {
  {
    "neovim/nvim-lspconfig",
    event = { "BufReadPre", "BufNewFile" },
    dependencies = {
      { "folke/neodev.nvim", opts = {} },
      "mason.nvim",
      "williamboman/mason-lspconfig.nvim",
    },
    config = function()
      -- Print a message when this loads
      vim.notify("LSP config is loading!")

      -- Make sure pyright is explicitly set up
      local lspconfig = require("lspconfig")
      lspconfig.pyright.setup({
        settings = {
          python = {
            analysis = {
              typeCheckingMode = "basic",
              diagnosticMode = "workspace",
              inlayHints = {
                variableTypes = true,
                functionReturnTypes = true,
              },
            },
          },
        },
        -- Force attach to Python files
        filetypes = { "python" },
      })

      -- Also set up ruff_lsp
      lspconfig.ruff_lsp.setup({
        -- Force attach to Python files
        filetypes = { "python" },
      })
    end,
  },
}
