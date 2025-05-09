return {
  {
    "Exafunction/codeium.nvim",
    event = "InsertEnter",
    dependencies = {
      "nvim-lua/plenary.nvim",
    },
    config = function()
      require("codeium").setup({
        config = {
          cmp_enabled = false, -- 🚫 disable cmp integration
        },
        keymaps = {
          accept = "<S-Tab>",
          accept_word = false,
          accept_line = false,
          next = "<M-]>",
          prev = "<M-[>",
          clear = "<C-]>",
        },
      })
    end,
  },
}
