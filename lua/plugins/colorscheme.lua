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
return {
  -- Gruvbox Hard theme with transparency and overrides
  {
    "ellisonleao/gruvbox.nvim",
    priority = 1000, -- Load before other plugins
    config = function()
      require("gruvbox").setup({
        contrast = "hard", -- 'soft', 'medium', or 'hard'
        transparent_mode = false,

        overrides = {
          -- Line numbers
          LineNr = { fg = "#a89984", bg = "NONE" },
          CursorLineNr = { fg = "#fabd2f", bold = true, bg = "NONE" },

          -- Status line
          StatusLine = { fg = "#ebdbb2", bg = "#3c3836" },

          -- Visual selection
          Visual = { bg = "#665c54" },

          -- Diagnostic highlights
          DiagnosticError = { fg = "#fb4934" },
          DiagnosticWarn = { fg = "#fabd2f" },
          DiagnosticInfo = { fg = "#83a598" },
          DiagnosticHint = { fg = "#d3869b" },
        },
      })

      vim.cmd("colorscheme gruvbox")
    end,
  },

  -- Set the colorscheme in LazyVim
  {
    "LazyVim/LazyVim",
    opts = {
      colorscheme = "gruvbox",
    },
  },
}

-- ~/.config/nvim/lua/plugins/vim-code-dark.lua
-- return {
--   -- Use onedark as the base theme - it has similar colors to what you're looking for
--   {
--     "navarasu/onedark.nvim",
--     lazy = false,
--     priority = 1000,
--     config = function()
--       require("onedark").setup({
--         -- Main options
--         style = "dark", -- Dark theme
--         transparent = true, -- Enable transparency
--         term_colors = true, -- Use terminal colors
--
--         -- Override specific highlight groups to match your VS Code theme
--         highlights = {
--           -- TypeScript specific highlights
--           ["@keyword"] = { fg = "#F92672" }, -- 'let' keyword in reddish color
--           ["@variable"] = { fg = "#BBBBBB" }, -- Variables in gray
--           ["@type"] = { fg = "#E6DB74" }, -- Types in yellow
--           ["@operator"] = { fg = "#FFFFFF" }, -- Operators in white
--           ["@number"] = { fg = "#AE81FF" }, -- Numbers in purple
--           ["@punctuation.delimiter"] = { fg = "#FFFFFF" }, -- Semicolons in white
--
--           -- Make background darker like VS Code dark hard
--           ["Normal"] = { bg = "#1E1E1E" },
--           ["NormalFloat"] = { bg = "#1E1E1E" },
--           ["SignColumn"] = { bg = "#1E1E1E" },
--
--           -- Additional typescript-specific highlights
--           ["@property"] = { fg = "#9CDCFE" }, -- Properties in light blue (VS Code style)
--           ["@function"] = { fg = "#DCDCAA" }, -- Functions in yellowish
--           ["@string"] = { fg = "#CE9178" }, -- Strings in orange-brown
--           ["@comment"] = { fg = "#6A9955" }, -- Comments in green
--
--           -- Ensure good contrast for selections
--           ["Visual"] = { bg = "#264F78" }, -- Selection background (VS Code style)
--         },
--       })
--
--       vim.cmd("colorscheme onedark")
--
--       -- Apply additional highlighting for TypeScript
--       vim.api.nvim_create_autocmd("FileType", {
--         pattern = { "typescript", "typescriptreact", "javascript", "javascriptreact" },
--         callback = function()
--           -- Further customize TypeScript highlighting
--           vim.api.nvim_set_hl(0, "@keyword.typescript", { fg = "#F92672" })
--           vim.api.nvim_set_hl(0, "@type.typescript", { fg = "#E6DB74" })
--           vim.api.nvim_set_hl(0, "@number.typescript", { fg = "#AE81FF" })
--         end,
--       })
--
--       -- Keep transparency settings from your existing config
--       vim.api.nvim_create_autocmd("ColorScheme", {
--         pattern = "*",
--         callback = function()
--           -- Remove background colors for transparency
--           vim.api.nvim_set_hl(0, "Normal", { bg = "NONE", ctermbg = "NONE" })
--           vim.api.nvim_set_hl(0, "NormalFloat", { bg = "NONE", ctermbg = "NONE" })
--           vim.api.nvim_set_hl(0, "NormalNC", { bg = "NONE", ctermbg = "NONE" })
--           vim.api.nvim_set_hl(0, "SignColumn", { bg = "NONE", ctermbg = "NONE" })
--           vim.api.nvim_set_hl(0, "EndOfBuffer", { bg = "NONE", ctermbg = "NONE" })
--           vim.api.nvim_set_hl(0, "LineNr", { bg = "NONE", ctermbg = "NONE" })
--         end,
--       })
--     end,
--   },
--
--   -- Override LazyVim's colorscheme
--   {
--     "LazyVim/LazyVim",
--     opts = {
--       colorscheme = "onedark",
--     },
--   },
-- }
