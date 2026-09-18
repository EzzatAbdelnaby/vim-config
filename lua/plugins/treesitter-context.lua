-- Treesitter Context - pin the enclosing scope at the top of the window
return {
  "nvim-treesitter/nvim-treesitter-context",
  event = { "BufReadPre", "BufNewFile" },
  dependencies = { "nvim-treesitter/nvim-treesitter" },
  opts = {
    max_lines = 3,
    trim_scope = "outer",
    mode = "cursor",
  },
}
