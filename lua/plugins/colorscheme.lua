-- Colorscheme configuration
-- Each colorscheme uses its native colors without modifications
return {
  -- Lake Dweller (default) - dark and atmospheric
  {
    "yonatan-perel/lake-dweller.nvim",
    name = "lake-dweller",
    lazy = true,
    config = function()
      require("lake-dweller").setup({})
    end,
  },

  -- Rose Pine - soft and elegant
  {
    "rose-pine/neovim",
    name = "rose-pine",
    priority = 1000,
    config = function()
      require("rose-pine").setup({
        variant = "moon",
        dark_variant = "moon",
        dim_inactive_windows = true,
        extend_background_behind_borders = true,
        styles = {
          bold = false,
          italic = true,
          transparency = true,
        },
        highlight_groups = {
          CursorLine = { bg = "none" },
        },
      })
      vim.cmd("colorscheme rose-pine")
    end,
  },

  -- Catppuccin - pastel and easy on eyes
  {
    "catppuccin/nvim",
    name = "catppuccin",
    lazy = true,
    config = function()
      require("catppuccin").setup({
        flavour = "mocha",
        transparent_background = true,
        dim_inactive = {
          enabled = true,
          percentage = 0.15,
        },
        styles = {
          comments = { "italic" },
          conditionals = {},
          loops = {},
          functions = {},
          keywords = {},
          strings = {},
          variables = {},
          numbers = {},
          booleans = {},
        },
        integrations = {
          cmp = true,
          gitsigns = true,
          treesitter = true,
          telescope = { enabled = true },
          which_key = true,
          flash = true,
          mini = { enabled = true },
          native_lsp = {
            enabled = true,
            underlines = {
              errors = { "undercurl" },
              hints = { "undercurl" },
              warnings = { "undercurl" },
              information = { "undercurl" },
            },
          },
        },
        custom_highlights = function()
          return {
            CursorLine = { bg = "none" },
          }
        end,
      })
    end,
  },

  -- Tokyo Night - clean and modern
  {
    "folke/tokyonight.nvim",
    lazy = true,
    config = function()
      require("tokyonight").setup({
        style = "night",
        transparent = true,
        dim_inactive = true,
        lualine_bold = false,
        styles = {
          comments = { italic = true },
          keywords = { italic = false },
          functions = {},
          variables = {},
          sidebars = "dark",
          floats = "dark",
        },
        on_highlights = function(hl)
          hl.CursorLine = { bg = "none" }
        end,
      })
    end,
  },

  -- Kanagawa - zen and calm
  {
    "rebelot/kanagawa.nvim",
    lazy = true,
    config = function()
      require("kanagawa").setup({
        theme = "wave",
        transparent = true,
        dimInactive = true,
        commentStyle = { italic = true },
        functionStyle = {},
        keywordStyle = {},
        statementStyle = {},
        typeStyle = {},
        overrides = function()
          return {
            CursorLine = { bg = "none" },
          }
        end,
      })
    end,
  },

  -- Gruvbox - warm and retro
  {
    "ellisonleao/gruvbox.nvim",
    lazy = true,
    config = function()
      require("gruvbox").setup({
        contrast = "soft",
        transparent_mode = true,
        dim_inactive = true,
        bold = false,
        italic = {
          strings = false,
          comments = true,
          operators = false,
          folds = true,
        },
        overrides = {
          CursorLine = { bg = "none" },
        },
      })
    end,
  },

}
