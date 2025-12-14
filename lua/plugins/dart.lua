-- Dart/Flutter configuration
return {
  -- DAP UI for debugging
  {
    "rcarriga/nvim-dap-ui",
    dependencies = {
      "mfussenegger/nvim-dap",
      "nvim-neotest/nvim-nio",
    },
    config = function()
      local dap, dapui = require("dap"), require("dapui")
      dapui.setup({
        layouts = {
          {
            elements = {
              { id = "scopes", size = 0.25 },
              { id = "breakpoints", size = 0.25 },
              { id = "stacks", size = 0.25 },
              { id = "watches", size = 0.25 },
            },
            position = "left",
            size = 40,
          },
          {
            elements = {
              { id = "repl", size = 0.5 },
              { id = "console", size = 0.5 },
            },
            position = "bottom",
            size = 10,
          },
        },
      })

      -- Auto open/close DAP UI
      dap.listeners.after.event_initialized["dapui_config"] = function()
        dapui.open()
      end
      dap.listeners.before.event_terminated["dapui_config"] = function()
        dapui.close()
      end
      dap.listeners.before.event_exited["dapui_config"] = function()
        dapui.close()
      end

      -- DAP keymaps
      vim.keymap.set("n", "<leader>du", dapui.toggle, { desc = "Toggle DAP UI" })
      vim.keymap.set("n", "<leader>db", dap.toggle_breakpoint, { desc = "Toggle breakpoint" })
      vim.keymap.set("n", "<leader>dB", function()
        dap.set_breakpoint(vim.fn.input("Breakpoint condition: "))
      end, { desc = "Conditional breakpoint" })
      vim.keymap.set("n", "<leader>dc", dap.continue, { desc = "Continue" })
      vim.keymap.set("n", "<leader>do", dap.step_over, { desc = "Step over" })
      vim.keymap.set("n", "<leader>di", dap.step_into, { desc = "Step into" })
      vim.keymap.set("n", "<leader>dO", dap.step_out, { desc = "Step out" })
      vim.keymap.set("n", "<leader>dr", dap.repl.open, { desc = "Open REPL" })
      vim.keymap.set("n", "<leader>dl", dap.run_last, { desc = "Run last" })
    end,
  },

  -- Flutter tools
  {
    "akinsho/flutter-tools.nvim",
    lazy = false, -- Load on startup so keymaps are always available
    dependencies = {
      "nvim-lua/plenary.nvim",
      "stevearc/dressing.nvim",
    },
    config = function()
      local flutter_tools = require("flutter-tools")

      -- Suppress annoying Dart LSP error with Copilot
      local notify = vim.notify
      vim.notify = function(msg, ...)
        if msg:match("textDocument/didChange") then
          return
        end
        notify(msg, ...)
      end

      flutter_tools.setup({
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
          -- Read launch configurations from .vscode/launch.json
          register_configurations = function(paths)
            if paths and paths.root then
              local launch_json = paths.root .. "/.vscode/launch.json"
              if vim.fn.filereadable(launch_json) == 1 then
                require("dap.ext.vscode").load_launchjs(launch_json, {
                  dart = { "dart" },
                })
              end
            end
          end,
        },
        flutter_path = "/Users/mac/fvm/default/bin/flutter", -- FVM default Flutter
        fvm = true, -- Also check project-specific FVM version (.fvm/flutter_sdk)
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

      -- Load telescope extension for flutter
      require("telescope").load_extension("flutter")

      -- Global Flutter keymaps (always visible in which-key)
      vim.keymap.set("n", "<leader>FF", "<cmd>FlutterRun<CR>", { desc = "Flutter run" })
      vim.keymap.set("n", "<leader>Fc", "<cmd>Telescope flutter commands<CR>", { desc = "Flutter commands" })
      vim.keymap.set("n", "<leader>Fo", "<cmd>FlutterOutlineToggle<CR>", { desc = "Flutter outline" })
      vim.keymap.set("n", "<leader>FR", "<cmd>FlutterReload<CR>", { desc = "Flutter reload" })
      vim.keymap.set("n", "<leader>Fr", "<cmd>FlutterRestart<CR>", { desc = "Flutter restart" })
      vim.keymap.set("n", "<leader>Fq", "<cmd>FlutterQuit<CR>", { desc = "Flutter quit" })
      vim.keymap.set("n", "<leader>Fd", "<cmd>FlutterDevices<CR>", { desc = "Flutter devices" })
      vim.keymap.set("n", "<leader>Fe", "<cmd>FlutterEmulators<CR>", { desc = "Flutter emulators" })
      vim.keymap.set("n", "<leader>Fl", "<cmd>FlutterLspRestart<CR>", { desc = "Flutter LSP restart" })
      vim.keymap.set("n", "<leader>Fg", "<cmd>FlutterPubGet<CR>", { desc = "Flutter pub get" })
      vim.keymap.set("n", "<leader>FL", "<cmd>FlutterLogToggle<CR>", { desc = "Flutter log toggle" })
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

  -- Formatting for Dart with conform.nvim
  {
    "stevearc/conform.nvim",
    ft = "dart",
    config = function()
      require("conform").setup({
        formatters_by_ft = {
          dart = { "dart_format" },
        },
        format_on_save = {
          lsp_fallback = false,
          async = false,
          timeout_ms = 2000,
        },
      })
    end,
  },

  -- Dart file settings
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
        end,
      })
    end,
  },

  -- Which-key group names
  {
    "folke/which-key.nvim",
    optional = true,
    opts = {
      spec = {
        { "<leader>F", group = "flutter", icon = "" },
        { "<leader>p", group = "packages" },
        { "<leader>d", group = "debug" },
      },
    },
  },

  -- Pubspec assist for package autocomplete
  {
    "akinsho/pubspec-assist.nvim",
    dependencies = {
      "nvim-lua/plenary.nvim",
    },
    ft = "yaml",
    config = function()
      require("pubspec-assist").setup()

      -- Keymaps for pubspec commands
      vim.api.nvim_create_autocmd("BufEnter", {
        pattern = "pubspec.yaml",
        callback = function()
          local opts = { buffer = true, silent = true }
          vim.keymap.set("n", "<leader>pa", "<cmd>PubspecAssistAddPackage<CR>", opts)
          vim.keymap.set("n", "<leader>pd", "<cmd>PubspecAssistAddDevPackage<CR>", opts)
          vim.keymap.set("n", "<leader>pv", "<cmd>PubspecAssistPickVersion<CR>", opts)
        end,
      })
    end,
  },

  -- Flutter/Dart snippets (Riverpod, BLoC, Freezed)
  {
    "L3MON4D3/LuaSnip",
    config = function()
      local ls = require("luasnip")
      local s = ls.snippet
      local t = ls.text_node
      local i = ls.insert_node
      local c = ls.choice_node

      ls.add_snippets("dart", {
        -- Riverpod providers
        s("riverpod", {
          t("final "), i(1, "name"), t("Provider = Provider<"), i(2, "Type"), t(">((ref) {"),
          t({ "", "  return " }), i(3, "value"), t(";"),
          t({ "", "});" }),
        }),
        s("riverpodstate", {
          t("final "), i(1, "name"), t("Provider = StateNotifierProvider<"), i(2, "Notifier"), t(", "), i(3, "State"), t(">((ref) {"),
          t({ "", "  return " }), i(4, "Notifier"), t("();"),
          t({ "", "});" }),
        }),
        s("riverpodfu", {
          t("final "), i(1, "name"), t("Provider = FutureProvider<"), i(2, "Type"), t(">((ref) async {"),
          t({ "", "  return " }), i(3, "value"), t(";"),
          t({ "", "});" }),
        }),
        s("consumerwidget", {
          t("class "), i(1, "Name"), t(" extends ConsumerWidget {"),
          t({ "", "  const " }), i(2, "Name"), t("({super.key});"),
          t({ "", "", "  @override", "  Widget build(BuildContext context, WidgetRef ref) {" }),
          t({ "", "    return " }), i(3, "Container()"), t(";"),
          t({ "", "  }", "}" }),
        }),

        -- BLoC patterns
        s("bloc", {
          t("class "), i(1, "Name"), t("Bloc extends Bloc<"), i(2, "Event"), t(", "), i(3, "State"), t("> {"),
          t({ "", "  " }), i(4, "Name"), t("Bloc() : super("), i(5, "InitialState"), t("()) {"),
          t({ "", "    on<" }), i(6, "Event"), t(">("), i(7, "_onEvent"), t(");"),
          t({ "", "  }", "}" }),
        }),
        s("cubit", {
          t("class "), i(1, "Name"), t("Cubit extends Cubit<"), i(2, "State"), t("> {"),
          t({ "", "  " }), i(3, "Name"), t("Cubit() : super("), i(4, "InitialState"), t("());"),
          t({ "", "", "  void " }), i(5, "method"), t("() {"),
          t({ "", "    emit(" }), i(6, "newState"), t(");"),
          t({ "", "  }", "}" }),
        }),
        s("blocbuilder", {
          t("BlocBuilder<"), i(1, "Bloc"), t(", "), i(2, "State"), t(">("),
          t({ "", "  builder: (context, state) {" }),
          t({ "", "    return " }), i(3, "Container()"), t(";"),
          t({ "", "  }," }),
          t({ "", ")" }),
        }),
        s("bloclistener", {
          t("BlocListener<"), i(1, "Bloc"), t(", "), i(2, "State"), t(">("),
          t({ "", "  listener: (context, state) {" }),
          t({ "", "    " }), i(3, "// handle state"),
          t({ "", "  }," }),
          t({ "", "  child: " }), i(4, "Container()"), t(","),
          t({ "", ")" }),
        }),

        -- Freezed
        s("freezed", {
          t("@freezed"),
          t({ "", "class " }), i(1, "Name"), t(" with _$"), i(2, "Name"), t(" {"),
          t({ "", "  const factory " }), i(3, "Name"), t("({"),
          t({ "", "    " }), i(4, "required String field"),
          t({ "", "  }) = _" }), i(5, "Name"), t(";"),
          t({ "", "", "  factory " }), i(6, "Name"), t(".fromJson(Map<String, dynamic> json) => _$"), i(7, "Name"), t("FromJson(json);"),
          t({ "", "}" }),
        }),

        -- Common Flutter widgets
        s("stl", {
          t("class "), i(1, "Name"), t(" extends StatelessWidget {"),
          t({ "", "  const " }), i(2, "Name"), t("({super.key});"),
          t({ "", "", "  @override", "  Widget build(BuildContext context) {" }),
          t({ "", "    return " }), i(3, "Container()"), t(";"),
          t({ "", "  }", "}" }),
        }),
        s("stf", {
          t("class "), i(1, "Name"), t(" extends StatefulWidget {"),
          t({ "", "  const " }), i(2, "Name"), t("({super.key});"),
          t({ "", "", "  @override", "  State<" }), i(3, "Name"), t("> createState() => _"), i(4, "Name"), t("State();"),
          t({ "", "}", "", "class _" }), i(5, "Name"), t("State extends State<"), i(6, "Name"), t("> {"),
          t({ "", "  @override", "  Widget build(BuildContext context) {" }),
          t({ "", "    return " }), i(7, "Container()"), t(";"),
          t({ "", "  }", "}" }),
        }),
      })
    end,
  },
}
