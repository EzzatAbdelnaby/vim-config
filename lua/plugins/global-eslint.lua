-- ~/.config/nvim/lua/plugins/global-eslint.lua
return {
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        eslint = {
          settings = {
            -- Use working directory as fallback
            workingDirectory = { mode = "auto" },
            -- Configure global configuration file as fallback
            options = {
              fallbackConfig = vim.fn.expand("~/.eslint/default-ts-eslintrc.js"),
              overrideConfigFile = function()
                -- Try to find local config first
                local local_config = vim.fn.findfile(".eslintrc.js", ".;")
                if local_config and local_config ~= "" then
                  return local_config
                end

                -- Fall back to global config
                return vim.fn.expand("~/.eslint/default-ts-eslintrc.js")
              end,
            },
            -- Don't throw errors when config isn't found
            useESLintClass = false,
            experimental = {
              useFlatConfig = false,
            },
            -- Don't fail on missing config
            requireConfigFile = false,
            -- Show warning instead of error
            problems = {
              shortenToSingleLine = false,
              diagnosticLevel = "warning",
            },
          },
        },
      },
    },
    config = function(_, opts)
      -- Add globally installed ESLint to path if needed
      local util = require("lspconfig.util")
      local node_path = vim.fn.trim(vim.fn.system("which node"))
      if node_path ~= "" then
        local node_bin_path = vim.fn.fnamemodify(node_path, ":h")
        local global_node_modules = vim.fn.trim(vim.fn.system("npm root -g"))

        -- Add these to the server path
        if global_node_modules ~= "" then
          opts.servers.eslint = opts.servers.eslint or {}
          opts.servers.eslint.cmd_env = {
            PATH = node_bin_path .. ":" .. global_node_modules .. "/.bin:" .. vim.env.PATH,
          }
        end
      end

      -- Call the original config function if it exists
      if opts.config then
        opts.config(_, opts)
      end
    end,
  },
}
