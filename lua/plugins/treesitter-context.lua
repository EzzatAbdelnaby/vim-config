-- lua/plugins/treesitter-context.lua
return {
  {
    "nvim-treesitter/nvim-treesitter-context",
    dependencies = "nvim-treesitter/nvim-treesitter",
    event = "BufReadPost",
    config = function()
      require("treesitter-context").setup({
        enable = true,
        max_lines = 3,
        min_window_height = 10,
        line_numbers = true,
        multiline_threshold = 20,
        trim_scope = "outer",
        mode = "cursor",
        separator = "─", -- Fancy separator
        zindex = 20,
      })

      -- Add highlight for better UI
      vim.api.nvim_set_hl(0, "TreesitterContext", { bg = "#2a2a3a", italic = true })
      vim.api.nvim_set_hl(0, "TreesitterContextLineNumber", { fg = "#7e86ab", bg = "#2a2a3a" })
      vim.api.nvim_set_hl(0, "TreesitterContextSeparator", { fg = "#3b3b5a" })

      -- Keymaps for navigating context
      vim.keymap.set("n", "[c", function()
        require("treesitter-context").go_to_context()
      end, { silent = true, desc = "Go to context (parent scope)" })
    end,
  },
}
