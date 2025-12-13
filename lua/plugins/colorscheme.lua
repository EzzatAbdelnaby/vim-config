-- Colorscheme configuration
-- Optimized for clean, minimal, non-distracting coding
return {
  -- Rose Pine (default) - soft and elegant
  {
    "rose-pine/neovim",
    name = "rose-pine",
    priority = 1000,
    config = function()
      require("rose-pine").setup({
        variant = "moon", -- moon is softer than main
        dark_variant = "moon",
        dim_inactive_windows = true,
        extend_background_behind_borders = true,
        styles = {
          bold = false, -- less visual noise
          italic = true, -- subtle emphasis for comments
          transparency = true,
        },
        groups = {
          border = "muted",
          link = "iris",
          panel = "surface",
          error = "love",
          hint = "muted", -- subtle hints
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
          -- Warm muted palette (matching screenshot)
          -- Base text / Variables: Soft cream
          Normal = { fg = "#D4C4A9" },
          Identifier = { fg = "#D4C4A9" },
          ["@variable"] = { fg = "#D4C4A9" },
          ["@parameter"] = { fg = "#D4C4A9" },
          ["@field"] = { fg = "#D4C4A9" },
          ["@property"] = { fg = "#D4C4A9" },

          -- Keywords: Muted rose/pink
          Keyword = { fg = "#C48B9F" },
          Statement = { fg = "#C48B9F" },
          Conditional = { fg = "#C48B9F" },
          Repeat = { fg = "#C48B9F" },
          ["@keyword"] = { fg = "#C48B9F" },
          ["@keyword.return"] = { fg = "#C48B9F" },
          ["@keyword.function"] = { fg = "#C48B9F" },
          ["@keyword.operator"] = { fg = "#C48B9F" },
          ["@keyword.import"] = { fg = "#C48B9F" },

          -- Functions: Muted teal/cyan
          Function = { fg = "#7AADAD" },
          ["@function"] = { fg = "#7AADAD" },
          ["@function.call"] = { fg = "#7AADAD" },
          ["@method"] = { fg = "#7AADAD" },
          ["@method.call"] = { fg = "#7AADAD" },

          -- Strings: Soft olive/sage green
          String = { fg = "#A9B37E" },
          Character = { fg = "#A9B37E" },
          ["@string"] = { fg = "#A9B37E" },

          -- Numbers/Booleans: Muted orange/peach
          Number = { fg = "#D4A373" },
          Boolean = { fg = "#D4A373" },
          ["@number"] = { fg = "#D4A373" },
          ["@boolean"] = { fg = "#D4A373" },

          -- Constants: Soft teal
          Constant = { fg = "#7AADAD" },
          ["@constant"] = { fg = "#7AADAD" },
          ["@constant.builtin"] = { fg = "#7AADAD" },

          -- Comments: Muted warm gray
          Comment = { italic = true, fg = "#7D7568" },
          ["@comment"] = { italic = true, fg = "#7D7568" },

          -- Types: Soft cream yellow
          Type = { fg = "#D4C078" },
          ["@type"] = { fg = "#D4C078" },
          ["@type.builtin"] = { fg = "#D4C078" },

          -- Punctuation: Muted gray
          ["@punctuation.bracket"] = { fg = "#9A8F80" },
          ["@punctuation.delimiter"] = { fg = "#9A8F80" },
          Delimiter = { fg = "#9A8F80" },
          Operator = { fg = "#9A8F80" },
          ["@operator"] = { fg = "#9A8F80" },

          -- UI elements
          CursorLine = { bg = "none" },
          ColorColumn = { bg = "none" },
          StatusLine = { fg = "#D4C4A9", bg = "none" },
          Search = { bg = "#C48B9F", fg = "base" },
          IncSearch = { bg = "#A9B37E", fg = "base" },
          LineNr = { fg = "#928374" },
          CursorLineNr = { fg = "#D4C4A9" },
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
        custom_highlights = function(colors)
          return {
            Comment = { fg = colors.overlay0, style = { "italic" } },
            LineNr = { fg = colors.overlay0 },
            CursorLineNr = { fg = colors.lavender },
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
        on_highlights = function(hl, c)
          hl.Comment = { fg = c.comment, italic = true }
          hl.LineNr = { fg = c.dark5 }
          hl.CursorLineNr = { fg = c.orange }
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
        colors = {
          theme = {
            all = {
              ui = {
                bg_gutter = "none", -- cleaner gutter
              },
            },
          },
        },
        overrides = function(colors)
          return {
            LineNr = { fg = "#727169" },
            CursorLineNr = { fg = colors.palette.roninYellow, bold = false },
            Comment = { fg = colors.palette.fujiGray, italic = true },
            CursorLine = { bg = "none" },
            CursorLineFold = { bg = "none" },
            CursorLineSign = { bg = "none" },
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
        contrast = "soft", -- soft is easier on eyes
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
          Comment = { italic = true },
          LineNr = { fg = "#928374" },
          CursorLineNr = { fg = "#fabd2f", bold = false },
          CursorLine = { bg = "none" },
        },
      })
    end,
  },

}
