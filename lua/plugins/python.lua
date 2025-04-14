-- ~/.config/nvim/lua/plugins/python.lua
return {
  -- Mason for tool installation
  {
    "williamboman/mason.nvim",
    opts = function(_, opts)
      vim.list_extend(opts.ensure_installed, {
        "pyright", -- Fast Python LSP
        "ruff-lsp", -- Fast Python linter and formatter
        "black", -- Code formatter
        "debugpy", -- Python debugger
        "isort", -- Import sorting
      })
    end,
  },

  -- LSP Configuration
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        -- Pyright for type checking and intellisense
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
              },
            },
          },
        },
        -- Ruff for fast linting
        ruff_lsp = {
          init_options = {
            settings = {
              -- Line length for formatting
              line_length = 88,
              -- Rules to determine code style
              select = {
                "E",
                "F",
                "I",
                "W", -- Default recommended rules
              },
              -- Any rules to ignore
              ignore = {},
            },
          },
        },
      },
    },
  },

  -- Code formatting
  {
    "stevearc/conform.nvim",
    optional = true,
    opts = {
      formatters_by_ft = {
        python = { "isort", "black" },
      },
    },
  },

  -- Python REPL & test runner
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
          -- Set Python Path to find tests accurately
          python = function()
            if vim.fn.filereadable(".venv/bin/python") == 1 then
              return ".venv/bin/python"
            elseif vim.fn.filereadable("venv/bin/python") == 1 then
              return "venv/bin/python"
            else
              return vim.fn.exepath("python3") or vim.fn.exepath("python") or "python"
            end
          end,
        },
      },
    },
    -- Add test runner bindings
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
        "<leader>td",
        function()
          require("neotest").run.run({ strategy = "dap" })
        end,
        desc = "Debug Test",
      },
    },
  },

  -- Debugger configuration
  {
    "mfussenegger/nvim-dap",
    dependencies = {
      "mfussenegger/nvim-dap-python",
      "rcarriga/nvim-dap-ui",
    },
    config = function()
      local path = require("mason-registry").get_package("debugpy"):get_install_path()
      require("dap-python").setup(path .. "/venv/bin/python")

      -- Add test methods
      require("dap-python").test_runner = "pytest"

      -- Configure virtual environments
      local get_python_path = function()
        if vim.fn.filereadable(".venv/bin/python") == 1 then
          return ".venv/bin/python"
        elseif vim.fn.filereadable("venv/bin/python") == 1 then
          return "venv/bin/python"
        else
          return vim.fn.exepath("python3") or vim.fn.exepath("python") or "python"
        end
      end

      require("dap-python").resolve_python = get_python_path
    end,
    keys = {
      {
        "<leader>db",
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
        desc = "Start/Continue Debugging",
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
        "<leader>dq",
        function()
          require("dap").terminate()
        end,
        desc = "Terminate Debug Session",
      },
    },
  },

  -- Virtual environment selector
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
    },
    keys = {
      { "<leader>cv", "<cmd>VenvSelect<cr>", desc = "Select Virtual Environment" },
      { "<leader>cd", "<cmd>VenvSelectCached<cr>", desc = "Select Last Environment" },
    },
  },
  {
    "nvim-telescope/telescope.nvim",
    keys = {
      {
        "<leader>rp",
        function()
          vim.cmd("terminal python3 " .. vim.fn.expand("%"))
        end,
        desc = "Run current Python file",
      },
    },
  },
}
