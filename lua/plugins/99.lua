return {
  {
    dir = "/Users/mac/Work/99",
    config = function()
      local _99 = require("99")
      local cwd = vim.uv.cwd()
      local basename = vim.fs.basename(cwd)

      _99.setup({
        -- provider = _99.Providers.ClaudeCodeProvider,
        model = "anthropic/claude-opus-4-6",
        logger = {
          level = _99.DEBUG,
          path = "/tmp/" .. basename .. ".99.debug",
          print_on_error = true,
        },
        tmp_dir = "./tmp",
        completion = {
          source = "cmp",
          custom_rules = {},
        },
        md_files = {
          "AGENT.md",
        },
      })

      -- AI search -> quickfix list
      vim.keymap.set("n", "<leader>9s", function()
        _99.search()
      end, { desc = "99: Search" })

      -- Replace visual selection with AI output
      vim.keymap.set("v", "<leader>9v", function()
        _99.visual()
      end, { desc = "99: Visual replace" })

      -- Cancel all in-flight requests
      vim.keymap.set("n", "<leader>9x", function()
        _99.stop_all_requests()
      end, { desc = "99: Stop requests" })

      -- Open previous results
      vim.keymap.set("n", "<leader>9o", function()
        _99.open()
      end, { desc = "99: Open results" })

      -- View logs
      vim.keymap.set("n", "<leader>9l", function()
        _99.view_logs()
      end, { desc = "99: View logs" })

      -- Chat with AI
      vim.keymap.set("n", "<leader>9c", function()
        _99.chat()
      end, { desc = "99: Chat" })

      -- Chat about visual selection
      vim.keymap.set("v", "<leader>9c", function()
        _99.visual_chat()
      end, { desc = "99: Chat about selection" })

      -- Tutorial / explain code
      vim.keymap.set("n", "<leader>9t", function()
        _99.tutorial()
      end, { desc = "99: Tutorial" })

      -- Telescope model/provider pickers (if telescope is available)
      vim.keymap.set("n", "<leader>9m", function()
        require("99.extensions.telescope").select_model()
      end, { desc = "99: Select model" })

      vim.keymap.set("n", "<leader>9p", function()
        require("99.extensions.telescope").select_provider()
      end, { desc = "99: Select provider" })
    end,
  },
}
