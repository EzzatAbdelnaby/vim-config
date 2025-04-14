return {
  {
    "kevinhwang91/nvim-ufo",
    dependencies = "kevinhwang91/promise-async",
    event = "BufRead",
    config = function()
      vim.o.foldcolumn = "1" -- Show fold column on the left
      vim.o.foldlevel = 99 -- Set high fold level so everything is open by default
      vim.o.foldlevelstart = 99
      vim.o.foldenable = true -- Enable folding

      require("ufo").setup({
        provider_selector = function(_, _, _)
          return { "treesitter", "indent" }
        end,
      })
    end,
  },
}
