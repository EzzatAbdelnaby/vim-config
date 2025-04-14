-- ~/.config/nvim/lua/plugins/typescript.lua
return {
  -- Mason for tool installation
  {
    "williamboman/mason.nvim",
    opts = function(_, opts)
      vim.list_extend(opts.ensure_installed, {
        "typescript-language-server", -- TypeScript LSP
        "eslint-lsp", -- ESLint LSP
        "prettier", -- Formatter
        "js-debug-adapter", -- JavaScript/TypeScript debugging
        "node-debug2-adapter", -- Node.js debugging
        "eslint_d", -- Fast ESLint
        "json-lsp", -- JSON LSP
      })
    end,
  },

  -- LSP Configuration
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        -- TypeScript LSP configuration
        tsserver = {
          settings = {
            typescript = {
              inlayHints = {
                includeInlayParameterNameHints = "all",
                includeInlayParameterNameHintsWhenArgumentMatchesName = false,
                includeInlayFunctionParameterTypeHints = true,
                includeInlayVariableTypeHints = true,
                includeInlayPropertyDeclarationTypeHints = true,
                includeInlayFunctionLikeReturnTypeHints = true,
                includeInlayEnumMemberValueHints = true,
              },
              suggest = {
                completeFunctionCalls = true,
              },
            },
            javascript = {
              inlayHints = {
                includeInlayParameterNameHints = "all",
                includeInlayParameterNameHintsWhenArgumentMatchesName = false,
                includeInlayFunctionParameterTypeHints = true,
                includeInlayVariableTypeHints = true,
                includeInlayPropertyDeclarationTypeHints = true,
                includeInlayFunctionLikeReturnTypeHints = true,
                includeInlayEnumMemberValueHints = true,
              },
              suggest = {
                completeFunctionCalls = true,
              },
            },
          },
        },

        -- ESLint LSP configuration
        eslint = {
          settings = {
            -- Settings for ESLint
            workingDirectory = { mode = "auto" },
            format = { enable = true },
            lint = { enable = true },
            codeAction = { disableRuleComment = { enable = true } },
          },
          -- Run ESLint when saving files
          on_attach = function(_, bufnr)
            vim.api.nvim_create_autocmd("BufWritePre", {
              buffer = bufnr,
              command = "EslintFixAll",
            })
          end,
        },

        -- JSON with JSON Schema support
        jsonls = {
          settings = {
            json = {
              validate = { enable = true },
              -- Basic schemas for common files
              schemas = {
                {
                  fileMatch = { "package.json" },
                  url = "https://json.schemastore.org/package.json",
                },
                {
                  fileMatch = { "tsconfig.json", "tsconfig.*.json" },
                  url = "https://json.schemastore.org/tsconfig.json",
                },
                {
                  fileMatch = { ".eslintrc.json", ".eslintrc" },
                  url = "https://json.schemastore.org/eslintrc.json",
                },
                {
                  fileMatch = { "next.config.js", "next.config.mjs" },
                  url = "https://json.schemastore.org/next.config.json",
                },
              },
            },
          },
        },
      },
      -- Configure TypeScript handler
      setup = {
        tsserver = function(_, opts)
          -- Use typescript.nvim for additional features if available
          if require("lazy.core.config").spec.plugins["typescript.nvim"] then
            require("typescript").setup({ server = opts })
            return true
          end
        end,
      },
    },
  },

  -- JSON Schema store for better JSON validation (optional)
  {
    "b0o/schemastore.nvim",
    lazy = true,
    cond = function()
      -- Only load if the plugin is available
      return pcall(require, "schemastore")
    end,
  },

  -- TypeScript.nvim for enhanced TypeScript support
  {
    "jose-elias-alvarez/typescript.nvim",
    dependencies = { "neovim/nvim-lspconfig" },
    config = function()
      require("typescript").setup({
        -- TypeScript server options
        server = {
          on_attach = function(client, bufnr)
            -- Setup keymaps for TypeScript specific features
            vim.keymap.set(
              "n",
              "<leader>co",
              "<cmd>TypescriptOrganizeImports<CR>",
              { buffer = bufnr, desc = "Organize Imports" }
            )
            vim.keymap.set("n", "<leader>cR", "<cmd>TypescriptRenameFile<CR>", { buffer = bufnr, desc = "Rename File" })
            vim.keymap.set(
              "n",
              "<leader>ci",
              "<cmd>TypescriptAddMissingImports<CR>",
              { buffer = bufnr, desc = "Add Missing Imports" }
            )
            vim.keymap.set(
              "n",
              "<leader>cu",
              "<cmd>TypescriptRemoveUnused<CR>",
              { buffer = bufnr, desc = "Remove Unused" }
            )
            vim.keymap.set("n", "<leader>cF", "<cmd>TypescriptFixAll<CR>", { buffer = bufnr, desc = "Fix All" })
            vim.keymap.set(
              "n",
              "<leader>cd",
              "<cmd>TypescriptGoToSourceDefinition<CR>",
              { buffer = bufnr, desc = "Go To Source Definition" }
            )
          end,
        },
      })
    end,
  },

  -- Add Prettier formatting
  {
    "stevearc/conform.nvim",
    optional = true,
    opts = {
      formatters_by_ft = {
        javascript = { "prettier" },
        javascriptreact = { "prettier" },
        typescript = { "prettier" },
        typescriptreact = { "prettier" },
        vue = { "prettier" },
        css = { "prettier" },
        scss = { "prettier" },
        less = { "prettier" },
        html = { "prettier" },
        json = { "prettier" },
        jsonc = { "prettier" },
        yaml = { "prettier" },
        markdown = { "prettier" },
        graphql = { "prettier" },
      },
    },
  },

  -- Add linting via nvim-lint
  {
    "mfussenegger/nvim-lint",
    optional = true,
    opts = {
      linters_by_ft = {
        javascript = { "eslint_d" },
        typescript = { "eslint_d" },
        javascriptreact = { "eslint_d" },
        typescriptreact = { "eslint_d" },
      },
    },
  },

  -- Add JavaScript debugging capabilities
  {
    "mfussenegger/nvim-dap",
    optional = true,
    dependencies = {
      {
        "rcarriga/nvim-dap-ui",
        keys = {
          {
            "<leader>du",
            function()
              require("dapui").toggle({})
            end,
            desc = "Dap UI",
          },
          {
            "<leader>de",
            function()
              require("dapui").eval()
            end,
            desc = "Eval",
            mode = { "n", "v" },
          },
        },
        opts = {},
        config = function(_, opts)
          local dap = require("dap")
          local dapui = require("dapui")
          dapui.setup(opts)
          dap.listeners.after.event_initialized["dapui_config"] = function()
            dapui.open({})
          end
          dap.listeners.before.event_terminated["dapui_config"] = function()
            dapui.close({})
          end
          dap.listeners.before.event_exited["dapui_config"] = function()
            dapui.close({})
          end
        end,
      },
    },
    config = function()
      -- Setup JavaScript/TypeScript debug adapter
      local dap = require("dap")
      dap.adapters["pwa-node"] = {
        type = "server",
        host = "localhost",
        port = "${port}",
        executable = {
          command = "node",
          args = {
            require("mason-registry").get_package("js-debug-adapter"):get_install_path()
              .. "/js-debug/src/dapDebugServer.js",
            "${port}",
          },
        },
      }

      -- For JavaScript/TypeScript
      dap.configurations.javascript = {
        {
          type = "pwa-node",
          request = "launch",
          name = "Launch file",
          program = "${file}",
          cwd = "${workspaceFolder}",
          sourceMaps = true,
        },
        {
          type = "pwa-node",
          request = "attach",
          name = "Attach",
          processId = require("dap.utils").pick_process,
          cwd = "${workspaceFolder}",
          sourceMaps = true,
        },
      }

      -- Use same config for TypeScript
      dap.configurations.typescript = dap.configurations.javascript

      -- For Next.js projects
      dap.configurations.typescriptreact = {
        {
          type = "pwa-chrome",
          request = "launch",
          name = "Next.js: Launch Chrome",
          url = "http://localhost:3000",
          webRoot = "${workspaceFolder}",
          sourceMaps = true,
        },
      }
      dap.configurations.javascriptreact = dap.configurations.typescriptreact

      -- For NestJS projects
      table.insert(dap.configurations.typescript, {
        type = "pwa-node",
        request = "launch",
        name = "NestJS: Launch Server",
        runtimeExecutable = "npm",
        runtimeArgs = {
          "run",
          "start:debug",
        },
        cwd = "${workspaceFolder}",
        sourceMaps = true,
        outFiles = { "${workspaceFolder}/dist/**/*.js" },
        console = "integratedTerminal",
      })
    end,
    keys = {
      {
        "<leader>dd",
        function()
          require("dap").toggle_breakpoint()
        end,
        desc = "Toggle Breakpoint",
      },
      {
        "<leader>dc",
        function()
          require("dap").continue()
        end,
        desc = "Continue",
      },
      {
        "<leader>do",
        function()
          require("dap").step_over()
        end,
        desc = "Step Over",
      },
      {
        "<leader>di",
        function()
          require("dap").step_into()
        end,
        desc = "Step Into",
      },
      {
        "<leader>ds",
        function()
          require("dap").step_out()
        end,
        desc = "Step Out",
      },
    },
  },

  -- Snippets for Next.js, React, etc.
  {
    "L3MON4D3/LuaSnip",
    dependencies = { "rafamadriz/friendly-snippets" },
    config = function()
      require("luasnip.loaders.from_vscode").lazy_load()
    end,
  },

  -- Add Telescope extensions
  {
    "nvim-telescope/telescope.nvim",
    keys = {
      -- Add specific keybindings for TypeScript
      {
        "<leader>fN",
        function()
          require("telescope.builtin").find_files({
            cwd = vim.fn.getcwd(),
            file_ignore_patterns = { "node_modules", ".git", "dist", "build", ".next" },
            prompt_title = "Next.js Files",
            path_display = { "truncate" },
          })
        end,
        desc = "Find Next.js Files",
      },
      {
        "<leader>fn",
        function()
          require("telescope.builtin").find_files({
            cwd = vim.fn.getcwd(),
            file_ignore_patterns = { "node_modules", ".git", "dist", "build" },
            prompt_title = "NestJS Files",
            path_display = { "truncate" },
          })
        end,
        desc = "Find NestJS Files",
      },
    },
  },

  -- Additional TreeSitter parsers for TypeScript
  {
    "nvim-treesitter/nvim-treesitter",
    opts = function(_, opts)
      vim.list_extend(opts.ensure_installed, {
        "typescript",
        "tsx",
        "javascript",
        "html",
        "css",
        "json",
        "yaml",
        "prisma",
        "graphql",
        "jsdoc",
      })
    end,
  },

  -- Add template string highlighting through Treesitter instead
  {
    "nvim-treesitter/nvim-treesitter",
    opts = function(_, opts)
      -- Make sure we highlight template strings properly in JSX/TSX
      if opts.highlight then
        opts.highlight.additional_vim_regex_highlighting = { "typescript", "tsx", "javascript", "jsx" }
      end
    end,
  },

  -- Keymaps for running TypeScript files
  {
    "nvim-telescope/telescope.nvim",
    keys = {
      {
        "<leader>rt",
        function()
          vim.cmd("terminal npx ts-node " .. vim.fn.expand("%"))
        end,
        desc = "Run current TypeScript file",
      },
      {
        "<leader>rn",
        function()
          vim.cmd("terminal npm run dev")
        end,
        desc = "Run Next.js dev server",
      },
      {
        "<leader>rb",
        function()
          vim.cmd("terminal npm run build")
        end,
        desc = "Build project",
      },
    },
  },
}
