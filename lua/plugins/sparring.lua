-- sparring.nvim - AI pair-engineer that makes you a better engineer, not a faster typist
return {
  dir = vim.fn.expand("~/Personal/sparring.nvim"),
  name = "sparring",
  event = "VeryLazy",
  config = function()
    require("sparring").setup()
  end,
}
