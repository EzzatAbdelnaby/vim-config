-- Colorscheme configuration
-- Each colorscheme uses its native colors without modifications
return {
  -- Lake Dweller - dark and atmospheric
  {
    "yonatan-perel/lake-dweller.nvim",
    name = "lake-dweller",
    lazy = true,
    config = function()
      require("lake-dweller").setup({ transparent = true })
    end,
  },

  -- Rose Pine (default) - soft and elegant
  {
    "rose-pine/neovim",
    name = "rose-pine",
    priority = 1000,
    config = function()
      require("rose-pine").setup({
        variant = "main",
        dark_variant = "main",
        dim_inactive_windows = true,
        extend_background_behind_borders = true,
        styles = {
          bold = false,
          italic = true,
          transparency = false,
        },
      })

      vim.cmd("colorscheme rose-pine")

      -- Forced directly (ColorMyPencils-style) so these always win,
      -- regardless of setup()/reload merge order.
      local overrides = {
        CursorLine = { bg = "none" },
        Normal = { bg = "#000000" },
        NormalNC = { bg = "#000000" },
        NormalFloat = { bg = "#000000" },
        SignColumn = { bg = "#000000" },
        EndOfBuffer = { bg = "#000000" },

        Function = { fg = "#EF9DAA" },
        ["@function"] = { fg = "#EF9DAA" },
        ["@function.call"] = { fg = "#EF9DAA" },
        ["@function.method"] = { fg = "#EF9DAA" },
        ["@function.method.call"] = { fg = "#EF9DAA" },

        Identifier = { fg = "#ADADCF" },
        ["@variable"] = { fg = "#ADADCF" },

        Keyword = { fg = "#817FB3" },
        ["@keyword"] = { fg = "#817FB3" },
        -- rose-pine defines @keyword.import (and other @keyword.* subgroups)
        -- explicitly, so they don't inherit from plain @keyword above.
        ["@keyword.import"] = { fg = "#817FB3" },
        ["@keyword.modifier"] = { fg = "#817FB3" },

        String = { fg = "#D9AD95" },
        ["@string"] = { fg = "#D9AD95" },

        Boolean = { fg = "#8EB2FF" },
        Constant = { fg = "#8EB2FF" },
        ["@boolean"] = { fg = "#8EB2FF" },
        ["@constant"] = { fg = "#8EB2FF" },
        ["@constant.builtin"] = { fg = "#8EB2FF" },

        Type = { fg = "#EF9DAA" },
        ["@type"] = { fg = "#EF9DAA" },
        ["@type.builtin"] = { fg = "#EF9DAA" },
        -- LSP semantic tokens (e.g. imported class/interface names) are a
        -- separate set of groups from plain treesitter @type captures.
        ["@lsp.type.class"] = { fg = "#EF9DAA" },
        ["@lsp.type.interface"] = { fg = "#EF9DAA" },
        ["@lsp.type.enum"] = { fg = "#EF9DAA" },
        ["@lsp.type.struct"] = { fg = "#EF9DAA" },
        ["@lsp.type.typeParameter"] = { fg = "#EF9DAA" },

        -- Built-in/standard-library types (Promise, Array, Record, ...)
        -- carry a "defaultLibrary" semantic modifier that your own classes
        -- don't, so this is the only reliable way to color them apart from
        -- Type above (there's no distinct group for "return type" itself).
        ["@lsp.mod.defaultLibrary"] = { fg = "#92BEB8" },
        ["@lsp.typemod.class.defaultLibrary"] = { fg = "#92BEB8" },
        ["@lsp.typemod.interface.defaultLibrary"] = { fg = "#92BEB8" },
        ["@lsp.typemod.type.defaultLibrary"] = { fg = "#92BEB8" },

        Include = { fg = "#B580A4" },
        ["@module"] = { fg = "#B580A4" },
        ["@namespace"] = { fg = "#B580A4" },
        ["@lsp.type.namespace"] = { fg = "#B580A4" },

        -- class/interface/enum declaration keywords
        ["@keyword.type"] = { fg = "#f6c177" },
        -- (), {}, [], <> pairs
        ["@punctuation.bracket"] = { fg = "#f6c177" },
        -- function/method parameters, same color as the class keyword
        ["@variable.parameter"] = { fg = "#f6c177", italic = true },

        -- decorator names, e.g. @ApiTags(...)
        ["@attribute"] = { fg = "#EF9DAA" },
      }

      for group, hl in pairs(overrides) do
        vim.api.nvim_set_hl(0, group, hl)
      end
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

  -- Nord - cold and minimal
  {
    "gbprod/nord.nvim",
    name = "nord",
    lazy = true,
    config = function()
      require("nord").setup({
        transparent = true,
        styles = {
          comments = { italic = true },
        },
      })
    end,
  },

  -- Koda - minimalist, quiet
  {
    "oskarnurm/koda.nvim",
    name = "koda",
    lazy = true,
    config = function()
      require("koda").setup({
        transparent = true,
        styles = {
          functions = { bold = true },
        },
      })
    end,
  },

}
