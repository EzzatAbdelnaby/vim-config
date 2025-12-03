-- Colorscheme configuration
return {
  {
    "rose-pine/neovim",
    name = "rose-pine",
    priority = 1000,
    config = function()
      require("rose-pine").setup({
        variant = "main", -- auto, main, moon, or dawn
        dark_variant = "main",
        dim_inactive_windows = false,
        extend_background_behind_borders = true,

        styles = {
          bold = true,
          italic = true,
          transparency = false,
        },

        groups = {
          border = "muted",
          link = "iris",
          panel = "surface",

          error = "love",
          hint = "iris",
          info = "foam",
          warn = "gold",

          git_add = "foam",
          git_change = "rose",
          git_delete = "love",
          git_dirty = "rose",
          git_ignore = "muted",
          git_merge = "iris",
          git_rename = "pine",
          git_stage = "iris",
          git_text = "rose",
          git_untracked = "subtle",
        },

        highlight_groups = {
          ColorColumn = { bg = "rose" },
          CursorLine = { bg = "surface" },
          StatusLine = { fg = "love", bg = "love", blend = 10 },
          Search = { bg = "gold", inherit = false },
          IncSearch = { bg = "iris" },
        },
      })

      vim.cmd("colorscheme rose-pine")
    end,
  },
}
