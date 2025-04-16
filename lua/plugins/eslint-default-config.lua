return {
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        eslint = {
          -- Tell ESLint not to require a config file
          settings = {
            workingDirectory = { mode = "auto" },
            format = { enable = true },
            lint = { enable = true },
            -- Use default rules when no config is found
            useESLintClass = false,
            experimental = { useFlatConfig = false },
            -- Don't require a config file
            requireConfigFile = false,
            -- Provide basic rules
            rulesCustomizations = {
              { rule = "*", severity = "warn" },
            },
          },
        },
      },
    },
  },

  -- Disable nvim-lint for TypeScript to avoid conflicts
  {
    "mfussenegger/nvim-lint",
    optional = true,
    opts = {
      linters_by_ft = {
        typescript = {}, -- Empty to use only ESLint LSP
        javascript = {},
      },
    },
  },
}
