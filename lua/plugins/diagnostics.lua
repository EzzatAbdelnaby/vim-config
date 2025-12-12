-- Better inline diagnostics
return {
  "rachartier/tiny-inline-diagnostic.nvim",
  event = "VeryLazy",
  priority = 1000,
  config = function()
    -- Disable default virtual text since tiny-inline-diagnostic replaces it
    vim.diagnostic.config({ virtual_text = false })

    require("tiny-inline-diagnostic").setup({
      preset = "modern",
      options = {
        show_source = true,
        multiple_diag_under_cursor = true,
        multilines = true,
        show_all_diags_on_cursorline = false,
        enable_on_insert = false,
      },
    })
  end,
}
