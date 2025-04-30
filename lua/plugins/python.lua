-- lua/plugins/python.lua
return {
  -- Mason configuration for Python tools
  {
    "williamboman/mason.nvim",
    opts = function(_, opts)
      opts.ensure_installed = opts.ensure_installed or {}
      vim.list_extend(opts.ensure_installed, {
        "pyright", -- Python LSP
        "ruff-lsp", -- Fast Python linter
        "black", -- Python formatter
        "isort", -- Import sorting
        "debugpy", -- Python debugger
        "mypy", -- Static type checker
      })
    end,
  },

  -- Configure LSP servers
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        -- Pyright configuration
        pyright = {
          settings = {
            python = {
              analysis = {
                typeCheckingMode = "basic",
                diagnosticMode = "workspace",
                inlayHints = {
                  variableTypes = true,
                  functionReturnTypes = true,
                },
                autoImportCompletions = true,
              },
            },
          },
        },
        -- Ruff configuration
        ruff_lsp = {
          init_options = {
            settings = {
              line_length = 88,
              select = {
                "E", -- pycodestyle errors
                "F", -- pyflakes
                "I", -- isort
                "W", -- pycodestyle warnings
              },
              ignore = {},
              fixable = { "A", "B", "C", "D", "E", "F", "G", "I", "N", "Q", "S", "T", "W" },
              unfixable = {},
            },
          },
        },
      },
    },
  },

  -- Code formatting configuration
  {
    "stevearc/conform.nvim",
    optional = true,
    opts = {
      formatters_by_ft = {
        python = { "isort", "black" },
      },
      formatters = {
        black = {
          args = { "--line-length=88", "--preview", "-" },
        },
        isort = {
          args = { "--profile", "black", "--line-length", "88", "-" },
        },
      },
    },
  },

  -- Linting setup
  {
    "mfussenegger/nvim-lint",
    optional = true,
    opts = {
      linters_by_ft = {
        python = { "mypy" },
      },
      linters = {
        mypy = {
          args = {
            "--ignore-missing-imports",
            "--disallow-untyped-defs",
            "--disallow-incomplete-defs",
            "--check-untyped-defs",
          },
        },
      },
    },
  },

  -- Testing configuration
  {
    "nvim-neotest/neotest",
    dependencies = {
      "nvim-neotest/neotest-python",
      "nvim-lua/plenary.nvim",
    },
    opts = {
      adapters = {
        ["neotest-python"] = {
          runner = "pytest",
          -- Get Python path intelligently
          python = function()
            if vim.fn.filereadable(".venv/bin/python") == 1 then
              return ".venv/bin/python"
            elseif vim.fn.filereadable("venv/bin/python") == 1 then
              return "venv/bin/python"
            else
              return vim.fn.exepath("python3") or vim.fn.exepath("python") or "python"
            end
          end,
          -- Additional pytest arguments
          args = {
            "--verbose",
            "--color=yes",
          },
        },
      },
    },
    -- Testing keymaps
    keys = {
      {
        "<leader>tt",
        function()
          require("neotest").run.run()
        end,
        desc = "Run Nearest Test",
      },
      {
        "<leader>tf",
        function()
          require("neotest").run.run(vim.fn.expand("%"))
        end,
        desc = "Run Test File",
      },
      {
        "<leader>ts",
        function()
          require("neotest").summary.toggle()
        end,
        desc = "Toggle Test Summary",
      },
      {
        "<leader>to",
        function()
          require("neotest").output.open()
        end,
        desc = "Open Test Output",
      },
      {
        "<leader>td",
        function()
          require("neotest").run.run({ strategy = "dap" })
        end,
        desc = "Debug Test",
      },
    },
  },

  -- Debugging setup
  {
    "mfussenegger/nvim-dap",
    dependencies = {
      "mfussenegger/nvim-dap-python",
      "rcarriga/nvim-dap-ui",
      "nvim-neotest/nvim-nio", -- Required dependency for dap-ui
    },
    config = function()
      local path = require("mason-registry").get_package("debugpy"):get_install_path()
      require("dap-python").setup(path .. "/venv/bin/python")

      -- Set pytest as test runner
      require("dap-python").test_runner = "pytest"

      -- Configure virtual environment detection
      local function get_python_path()
        if vim.fn.filereadable(".venv/bin/python") == 1 then
          return ".venv/bin/python"
        elseif vim.fn.filereadable("venv/bin/python") == 1 then
          return "venv/bin/python"
        else
          return vim.fn.exepath("python3") or vim.fn.exepath("python") or "python"
        end
      end

      require("dap-python").resolve_python = get_python_path

      -- Initialize DAP UI
      local dapui = require("dapui")
      dapui.setup({
        layouts = {
          {
            elements = {
              { id = "scopes", size = 0.4 },
              { id = "breakpoints", size = 0.15 },
              { id = "stacks", size = 0.15 },
              { id = "watches", size = 0.3 },
            },
            size = 0.3,
            position = "right",
          },
          {
            elements = {
              { id = "repl", size = 0.5 },
              { id = "console", size = 0.5 },
            },
            size = 0.3,
            position = "bottom",
          },
        },
      })

      -- Auto-open DAP UI
      local dap = require("dap")
      dap.listeners.after.event_initialized["dapui_config"] = function()
        dapui.open()
      end
      dap.listeners.before.event_terminated["dapui_config"] = function()
        dapui.close()
      end
      dap.listeners.before.event_exited["dapui_config"] = function()
        dapui.close()
      end
    end,
    -- Debugging keymaps
    keys = {
      {
        "<leader>db",
        function()
          require("dap").toggle_breakpoint()
        end,
        desc = "Toggle Breakpoint",
      },
      {
        "<leader>dB",
        function()
          require("dap").set_breakpoint(vim.fn.input("Breakpoint condition: "))
        end,
        desc = "Breakpoint Condition",
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
        "<leader>dO",
        function()
          require("dap").step_out()
        end,
        desc = "Step Out",
      },
      {
        "<leader>dt",
        function()
          require("dap").terminate()
        end,
        desc = "Terminate",
      },
      {
        "<leader>dr",
        function()
          require("dap").repl.toggle()
        end,
        desc = "Toggle REPL",
      },
      {
        "<leader>dq",
        function()
          require("dap").disconnect()
          require("dapui").close()
        end,
        desc = "Disconnect",
      },
      {
        "<leader>dK",
        function()
          require("dapui").eval()
        end,
        mode = { "n", "v" },
        desc = "Evaluate Expression",
      },
    },
  },

  -- Virtual environment manager
  {
    "linux-cultist/venv-selector.nvim",
    dependencies = {
      "neovim/nvim-lspconfig",
      "nvim-telescope/telescope.nvim",
      "mfussenegger/nvim-dap-python",
    },
    opts = {
      name = {
        "venv",
        ".venv",
        "env",
        ".env",
      },
      auto_refresh = true,
      search_workspace = true,
      parents = 3, -- Search 3 levels up for venvs
    },
    -- Virtual environment keymaps
    keys = {
      { "<leader>cv", "<cmd>VenvSelect<cr>", desc = "Select Virtual Environment" },
      { "<leader>cd", "<cmd>VenvSelectCached<cr>", desc = "Select Last Virtual Environment" },
    },
  },

  -- Additional Python-specific keymaps
  {
    "nvim-telescope/telescope.nvim",
    optional = true,
    keys = {
      {
        "<leader>rp",
        function()
          vim.cmd("terminal python3 " .. vim.fn.expand("%"))
        end,
        desc = "Run Python File",
      },
      {
        "<leader>pi",
        function()
          vim.cmd("terminal pip install -r requirements.txt")
        end,
        desc = "Install Requirements",
      },
    },
  },

  -- Python-specific snippets
  {
    "L3MON4D3/LuaSnip",
    optional = true,
    config = function(_, opts)
      require("luasnip").add_snippets("python", {
        -- Add your custom Python snippets here
        -- Example:
        -- s("def", fmt("def {}({}):\n\t{}", { i(1, "name"), i(2), i(3, "pass") })),
      })
    end,
  },
}
