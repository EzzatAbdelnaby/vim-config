return {
  -- GitHub Copilot with inline suggestions
  {
    "zbirenbaum/copilot.lua",
    cmd = "Copilot",
    event = "InsertEnter",
    config = function()
      require("copilot").setup({
        suggestion = {
          enabled = true,
          auto_trigger = true,
          keymap = {
            accept = "<Tab>", -- Accept suggestion with Tab
            accept_word = false,
            accept_line = false,
            next = "<M-]>", -- Alt + ]
            prev = "<M-[>", -- Alt + [
            dismiss = "<C-]>", -- Ctrl + ]
          },
        },
        panel = {
          enabled = true,
          auto_refresh = true,
        },
        filetypes = {
          markdown = true,
          yaml = true,
          ["."] = true, -- Enable for all filetypes
        },
      })
    end,
  },

  -- Uncomment the section below ONLY if you want CMP integration and have nvim-cmp installed
  -- {
  --   "zbirenbaum/copilot-cmp",
  --   dependencies = {
  --     "hrsh7th/nvim-cmp",
  --     "zbirenbaum/copilot.lua",
  --   },
  --   config = function()
  --     require("copilot_cmp").setup()
  --   end,
  -- },
}
