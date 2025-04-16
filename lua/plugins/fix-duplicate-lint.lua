-- ~/.config/nvim/lua/plugins/fix-duplicate-lint.lua
return {
  -- Adjust LSP configuration to prevent duplicate linting
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        -- Configure ESLint to be the one source of linting
        eslint = {
          settings = {
            -- Enable only onSave to reduce duplicated linting
            run = "onSave",
          },
        },
      },
    },
  },

  -- Explicitly disable nvim-lint for TypeScript (if it's being used)
  {
    "mfussenegger/nvim-lint",
    optional = true,
    opts = {
      -- Remove TypeScript from nvim-lint to avoid duplicate linting
      linters_by_ft = {
        typescript = {}, -- Empty array disables linting
        javascript = {}, -- Empty array disables linting
        typescriptreact = {}, -- Empty array disables linting
        javascriptreact = {}, -- Empty array disables linting
      },
    },
  },

  -- If using conform.nvim, ensure it doesn't also run eslint formatting
  {
    "stevearc/conform.nvim",
    optional = true,
    opts = {
      formatters_by_ft = {
        -- Ensure only prettier is used, not eslint
        typescript = { "prettier" },
        javascript = { "prettier" },
        typescriptreact = { "prettier" },
        javascriptreact = { "prettier" },
      },
    },
  },
}
