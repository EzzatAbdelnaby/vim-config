-- -- ~/.config/nvim/lua/plugins/colorscheme.lua
-- return {
--   -- Rose Pine theme with transparent background
--   {
--     "rose-pine/neovim",
--     name = "rose-pine",
--     priority = 1000, -- Load this before other plugins
--     config = function()
--       require("rose-pine").setup({
--         variant = "moon", -- Options: 'auto', 'main', 'moon', or 'dawn'
--         dark_variant = "moon", -- The theme variant to use when dark mode is detected
--         dim_inactive_windows = false,
--         extend_background_behind_borders = true,
--
--         -- Enable transparent background
--         transparent = true,
--
--         -- Disable background completely
--         disable_background = true,
--
--         -- Disable float background
--         disable_float_background = true,
--
--         -- Configure any additional style options
--         styles = {
--           bold = true,
--           italic = false,
--           transparency = true,
--         },
--
--         -- Override specific highlight groups
--         highlight_groups = {
--           -- Make sure line numbers are visible
--           LineNr = { fg = "rose", bg = "none" },
--           CursorLineNr = { fg = "gold", bold = true, bg = "none" },
--
--           -- Make sure status line is visible
--           StatusLine = { fg = "subtle", bg = "surface" },
--
--           -- Ensure good visibility for selections
--           Visual = { bg = "pine", blend = 10 },
--
--           -- Ensure good contrast for diagnostics
--           DiagnosticError = { fg = "love" },
--           DiagnosticWarn = { fg = "gold" },
--           DiagnosticInfo = { fg = "foam" },
--           DiagnosticHint = { fg = "iris" },
--         },
--       })
--     end,
--   },
--
--   -- Set the colorscheme
--   {
--     "LazyVim/LazyVim",
--     opts = {
--       colorscheme = "rose-pine",
--     },
--   },
-- }
-- return {
--   -- Gruvbox Hard theme with transparency and overrides
--   {
--     "ellisonleao/gruvbox.nvim",
--     priority = 1000, -- Load before other plugins
--     config = function()
--       require("gruvbox").setup({
--         contrast = "hard", -- 'soft', 'medium', or 'hard'
--
--         overrides = {
--           -- Line numbers
--           LineNr = { fg = "#a89984", bg = "NONE" },
--           CursorLineNr = { fg = "#fabd2f", bold = true, bg = "NONE" },
--
--           -- Status line
--           StatusLine = { fg = "#ebdbb2", bg = "#3c3836" },
--
--           -- Visual selection
--           Visual = { bg = "#665c54" },
--
--           -- Diagnostic highlights
--           DiagnosticError = { fg = "#fb4934" },
--           DiagnosticWarn = { fg = "#fabd2f" },
--           DiagnosticInfo = { fg = "#83a598" },
--           DiagnosticHint = { fg = "#d3869b" },
--         },
--       })
--
--       vim.cmd("colorscheme gruvbox")
--     end,
--   },
--
--   -- Set the colorscheme in LazyVim
--   {
--     "LazyVim/LazyVim",
--     opts = {
--       colorscheme = "gruvbox",
--     },
--   },
-- }

return {
  -- Moonfly colorscheme
  {
    "bluz71/vim-moonfly-colors",
    name = "moonfly",
    priority = 1000,
  },

  -- Set Moonfly as the colorscheme
  {
    "LazyVim/LazyVim",
    opts = {
      colorscheme = "moonfly",
    },
  },
}
