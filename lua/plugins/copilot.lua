
return {
  -- Official GitHub Copilot
  {
    "github/copilot.vim",
    event = "InsertEnter",
    config = function()
      -- Disable default tab mapping
      vim.g.copilot_no_tab_map = true

      -- Custom keymaps
      vim.keymap.set("i", "<Tab>", 'copilot#Accept("<CR>")', {
        expr = true,
        replace_keycodes = false,
        desc = "Accept Copilot suggestion",
      })

      vim.keymap.set("i", "<M-]>", "<Plug>(copilot-next)", { desc = "Next Copilot suggestion" })
      vim.keymap.set("i", "<M-[>", "<Plug>(copilot-previous)", { desc = "Previous Copilot suggestion" })
      vim.keymap.set("i", "<M-\\>", "<Plug>(copilot-suggest)", { desc = "Trigger Copilot suggestion" })
      vim.keymap.set("i", "<C-]>", "<Plug>(copilot-dismiss)", { desc = "Dismiss Copilot suggestion" })

      -- Filetypes where Copilot is disabled
      vim.g.copilot_filetypes = {
        ["*"] = true,
        ["gitcommit"] = false,
        ["gitrebase"] = false,
        ["yaml"] = false,
        ["markdown"] = false,
      }
    end,
  },

  -- Copilot Chat
  {
    "CopilotC-Nvim/CopilotChat.nvim",
    branch = "canary",
    dependencies = {
      { "github/copilot.vim" },
      { "nvim-lua/plenary.nvim" },
    },
    cmd = {
      "CopilotChat",
      "CopilotChatOpen",
      "CopilotChatClose",
      "CopilotChatToggle",
      "CopilotChatReset",
      "CopilotChatExplain",
      "CopilotChatReview",
      "CopilotChatFix",
      "CopilotChatOptimize",
      "CopilotChatDocs",
      "CopilotChatTests",
    },
    keys = {
      {
        "<leader>cce",
        "<cmd>CopilotChatExplain<cr>",
        mode = { "n", "v" },
        desc = "Copilot: Explain code",
      },
      {
        "<leader>cct",
        "<cmd>CopilotChatTests<cr>",
        mode = { "n", "v" },
        desc = "Copilot: Generate tests",
      },
      {
        "<leader>ccr",
        "<cmd>CopilotChatReview<cr>",
        mode = { "n", "v" },
        desc = "Copilot: Review code",
      },
      {
        "<leader>ccf",
        "<cmd>CopilotChatFix<cr>",
        mode = { "n", "v" },
        desc = "Copilot: Fix code",
      },
      {
        "<leader>cco",
        "<cmd>CopilotChatOptimize<cr>",
        mode = { "n", "v" },
        desc = "Copilot: Optimize code",
      },
      {
        "<leader>ccd",
        "<cmd>CopilotChatDocs<cr>",
        mode = { "n", "v" },
        desc = "Copilot: Generate docs",
      },
      {
        "<leader>cch",
        "<cmd>CopilotChatToggle<cr>",
        desc = "Copilot: Toggle chat",
      },
    },
    config = function()
      require("CopilotChat").setup({
        debug = false,
        show_help = "yes",
        prompts = {
          Explain = "Explain how this code works.",
          Review = "Review this code and provide suggestions.",
          Tests = "Generate tests for this code.",
          Refactor = "Refactor this code to improve its clarity and readability.",
          FixCode = "Fix the following code to make it work as intended.",
          FixError = "Explain this error and provide a solution.",
          BetterNamings = "Provide better names for the following variables and functions.",
          Documentation = "Write documentation for this code.",
          SwaggerApiDocs = "Write Swagger API documentation for this code.",
          SwaggerJsDocs = "Write JSDoc annotations for this code.",
          Summarize = "Summarize this code.",
          Spelling = "Fix spelling and grammar in this text.",
          Wording = "Improve the wording of this text.",
          Concise = "Make this text more concise.",
        },
        auto_insert_mode = true,
        show_folds = true,
        insert_at_end = false,
        clear_chat_on_new_prompt = false,
        highlight_selection = true,
        context = nil,
        window = {
          layout = "vertical",
          width = 0.4,
          height = 0.6,
          border = "rounded",
        },
        mappings = {
          complete = {
            insert = "<Tab>",
          },
          close = {
            normal = "q",
            insert = "<C-c>",
          },
          reset = {
            normal = "<C-r>",
            insert = "<C-r>",
          },
          submit_prompt = {
            normal = "<CR>",
            insert = "<C-s>",
          },
          accept_diff = {
            normal = "<C-y>",
            insert = "<C-y>",
          },
          yank_diff = {
            normal = "gy",
          },
          show_diff = {
            normal = "gd",
          },
          show_system_prompt = {
            normal = "gp",
          },
          show_user_selection = {
            normal = "gs",
          },
        },
      })
    end,
  },

  -- Which-key groups
  {
    "folke/which-key.nvim",
    optional = true,
    opts = {
      spec = {
        { "<leader>cc", group = "copilot-chat" },
      },
    },
  },
}
