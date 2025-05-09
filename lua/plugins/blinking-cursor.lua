return {
  "jszakmeister/vim-togglecursor",
  lazy = false, -- We want this to load right away
  priority = 1000, -- Give it high priority
  config = function()
    -- You can add any specific configuration here if needed
    vim.g.togglecursor_default = "blinking_block"
    vim.g.togglecursor_insert = "blinking_line"
    vim.g.togglecursor_replace = "blinking_underline"
    vim.g.togglecursor_leave = "block"
  end,
}
