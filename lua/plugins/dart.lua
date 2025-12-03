-- Dart/Flutter configuration
return {
  -- Flutter tools
  {
    "akinsho/flutter-tools.nvim",
    ft = "dart",
    dependencies = {
      "nvim-lua/plenary.nvim",
      "stevearc/dressing.nvim",
    },
    config = function()
      require("flutter-tools").setup({
        ui = {
          border = "rounded",
          notification_style = "native",
        },
        decorations = {
          statusline = {
            app_version = true,
            device = true,
            project_config = true,
          },
        },
        debugger = {
          enabled = true,
          run_via_dap = true,
          exception_breakpoints = {},
        },
        flutter_path = nil, -- Uses flutter from PATH
        fvm = true, -- Enable FVM support
        widget_guides = {
          enabled = true,
        },
        closing_tags = {
          highlight = "Comment",
          prefix = " // ",
          enabled = true,
        },
        dev_log = {
          enabled = true,
          notify_errors = true,
        },
        dev_tools = {
          autostart = false,
          auto_open_browser = false,
        },
        outline = {
          open_cmd = "30vnew",
          auto_open = false,
        },
        lsp = {
          color = {
            enabled = true,
            background = false,
            virtual_text = true,
            virtual_text_str = "■",
          },
          on_attach = function(client, bufnr)
            local opts = { buffer = bufnr, silent = true }

            -- Standard LSP keymaps
            vim.keymap.set("n", "gR", "<cmd>Telescope lsp_references<CR>", opts)
            vim.keymap.set("n", "gD", vim.lsp.buf.declaration, opts)
            vim.keymap.set("n", "gd", "<cmd>Telescope lsp_definitions<CR>", opts)
            vim.keymap.set("n", "gi", "<cmd>Telescope lsp_implementations<CR>", opts)
            vim.keymap.set("n", "gt", "<cmd>Telescope lsp_type_definitions<CR>", opts)
            vim.keymap.set({ "n", "v" }, "<leader>ca", vim.lsp.buf.code_action, opts)
            vim.keymap.set("n", "<leader>rn", vim.lsp.buf.rename, opts)
            vim.keymap.set("n", "<leader>D", "<cmd>Telescope diagnostics bufnr=0<CR>", opts)
            vim.keymap.set("n", "<leader>d", vim.diagnostic.open_float, opts)
            vim.keymap.set("n", "[d", vim.diagnostic.goto_prev, opts)
            vim.keymap.set("n", "]d", vim.diagnostic.goto_next, opts)
            vim.keymap.set("n", "K", vim.lsp.buf.hover, opts)
            vim.keymap.set("n", "<leader>rs", ":LspRestart<CR>", opts)

            -- Flutter-specific keymaps
            vim.keymap.set("n", "<leader>fc", "<cmd>FlutterOutlineToggle<CR>", opts)
            vim.keymap.set("n", "<leader>fR", "<cmd>FlutterReload<CR>", opts)
            vim.keymap.set("n", "<leader>fr", "<cmd>FlutterRestart<CR>", opts)
            vim.keymap.set("n", "<leader>fq", "<cmd>FlutterQuit<CR>", opts)
            vim.keymap.set("n", "<leader>fd", "<cmd>FlutterDevices<CR>", opts)
            vim.keymap.set("n", "<leader>fe", "<cmd>FlutterEmulators<CR>", opts)
            vim.keymap.set("n", "<leader>fl", "<cmd>FlutterLspRestart<CR>", opts)
          end,
          capabilities = require("cmp_nvim_lsp").default_capabilities(),
          settings = {
            showTodos = true,
            completeFunctionCalls = true,
            renameFilesWithClasses = "prompt",
            enableSnippets = true,
            updateImportsOnRename = true,
          },
        },
      })
    end,
  },

  -- Treesitter for Dart
  {
    "nvim-treesitter/nvim-treesitter",
    opts = function(_, opts)
      if type(opts.ensure_installed) == "table" then
        vim.list_extend(opts.ensure_installed, { "dart" })
      end
    end,
  },

  -- Formatting for Dart
  {
    "stevearc/conform.nvim",
    opts = function(_, opts)
      opts.formatters_by_ft = opts.formatters_by_ft or {}
      opts.formatters_by_ft.dart = { "dart_format" }
      opts.formatters = opts.formatters or {}
      opts.formatters.dart_format = {
        command = "dart",
        args = { "format" },
      }
    end,
  },

  -- Auto-format Dart files on save
  {
    "neovim/nvim-lspconfig",
    opts = function()
      vim.api.nvim_create_autocmd("FileType", {
        pattern = "dart",
        callback = function()
          -- Set tab width to 2 spaces (Dart convention)
          vim.opt_local.tabstop = 2
          vim.opt_local.shiftwidth = 2
          vim.opt_local.expandtab = true

          -- Enable format on save
          vim.api.nvim_create_autocmd("BufWritePre", {
            buffer = 0,
            callback = function()
              vim.lsp.buf.format({ async = false })
            end,
          })
        end,
      })
    end,
  },

  -- Pub package manager commands
  {
    "folke/which-key.nvim",
    optional = true,
    opts = {
      defaults = {
        ["<leader>f"] = { name = "+flutter" },
        ["<leader>p"] = { name = "+packages" },
      },
    },
  },
}
