-- ~/.config/nvim/lua/plugins/diagnostics-improved.lua
return {
  -- Configure built-in diagnostics
  {
    "LazyVim/LazyVim",
    opts = function()
      -- Improve built-in diagnostics display
      vim.diagnostic.config({
        -- Make diagnostics visible in insert mode
        update_in_insert = true,

        -- Improve how diagnostics are displayed
        float = {
          border = "rounded",
          source = "always", -- Always show source
          header = "", -- No header
          prefix = " ", -- Space prefix for cleaner look
          format = function(diagnostic)
            -- Format the diagnostic to show on multiple lines for better readability
            local message = diagnostic.message
            local source = diagnostic.source

            -- If the message is too long, wrap it
            if #message > 80 then
              message = message:sub(1, 80) .. "..."
            end

            return message
          end,
        },

        -- Better virtual text (inline diagnostics)
        virtual_text = {
          spacing = 4, -- More space before virtual text
          source = "if_many", -- Only show source if multiple diagnostics
          prefix = "●", -- Use a dot as prefix
          format = function(diagnostic)
            -- Format virtual text for better readability
            if diagnostic.severity == vim.diagnostic.severity.ERROR then
              return string.format("Error: %s", diagnostic.message:gsub("\n", " "))
            elseif diagnostic.severity == vim.diagnostic.severity.WARN then
              return string.format("Warning: %s", diagnostic.message:gsub("\n", " "))
            elseif diagnostic.severity == vim.diagnostic.severity.INFO then
              return string.format("Info: %s", diagnostic.message:gsub("\n", " "))
            else
              return diagnostic.message:gsub("\n", " ")
            end
          end,
        },

        -- Enable severity sorting
        severity_sort = true,
      })

      -- Add keymap to show diagnostics in floating window
      vim.keymap.set("n", "<leader>d", vim.diagnostic.open_float, { desc = "Show Diagnostics" })
      vim.keymap.set("i", "<C-d>", function()
        vim.diagnostic.open_float()
      end, { desc = "Show Diagnostics in Insert Mode" })

      -- Add custom highlighting for better visibility
      vim.api.nvim_set_hl(0, "DiagnosticVirtualTextError", { fg = "#FF6D7E", bg = "#331c1e" })
      vim.api.nvim_set_hl(0, "DiagnosticVirtualTextWarn", { fg = "#FFD866", bg = "#332e1e" })
      vim.api.nvim_set_hl(0, "DiagnosticVirtualTextInfo", { fg = "#5CCFE6", bg = "#1e2e33" })
      vim.api.nvim_set_hl(0, "DiagnosticVirtualTextHint", { fg = "#A9DC76", bg = "#1e331e" })

      -- Better underline colors
      vim.api.nvim_set_hl(0, "DiagnosticUnderlineError", { sp = "#FF6D7E", undercurl = true })
      vim.api.nvim_set_hl(0, "DiagnosticUnderlineWarn", { sp = "#FFD866", undercurl = true })
      vim.api.nvim_set_hl(0, "DiagnosticUnderlineInfo", { sp = "#5CCFE6", undercurl = true })
      vim.api.nvim_set_hl(0, "DiagnosticUnderlineHint", { sp = "#A9DC76", undercurl = true })

      -- Add auto-command to show diagnostics on cursor hold even in insert mode
      vim.api.nvim_create_autocmd({ "CursorHold", "CursorHoldI" }, {
        callback = function()
          -- Only show diagnostics if there are any at cursor position
          local line = vim.fn.line(".")
          local col = vim.fn.col(".")
          local diagnostics = vim.diagnostic.get(0, { lnum = line - 1 })

          if #diagnostics > 0 then
            vim.diagnostic.open_float(nil, {
              scope = "cursor",
              focus = false,
            })
          end
        end,
      })
    end,
  },

  -- Enhanced UI for diagnostics with better styling
  {
    "folke/trouble.nvim",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    opts = {
      position = "bottom", -- Position at the bottom
      height = 10, -- Height of the trouble list
      width = 50, -- Width of the trouble list
      use_diagnostic_signs = true, -- Use signs defined by LSP client

      -- Fix icons configuration by using the proper icons setup
      signs = {
        -- Icons / text used for diagnostics
        error = "",
        warning = "",
        hint = "",
        information = "",
        other = "",
      },

      mode = "workspace_diagnostics", -- Show workspace diagnostics
      fold_open = "▾", -- Icon for open folds
      fold_closed = "▸", -- Icon for closed folds
      group = true, -- Group results by file
      padding = true, -- Add padding
      action_keys = {
        close = "q", -- Close trouble window
        cancel = "<esc>", -- Cancel
        refresh = "r", -- Refresh
        jump = { "<cr>", "<tab>" }, -- Jump to the diagnostic
        toggle_fold = { "zA", "za" }, -- Toggle fold
        previous = "k", -- Previous item
        next = "j", -- Next item
      },
      indent_lines = true, -- Add indent lines
      auto_close = false, -- Automatically close when selecting
    },
    config = function(_, opts)
      require("trouble").setup(opts)

      -- Fix issue with lualine integration by ensuring api.statusline is compatible
      local trouble_api = require("trouble.api")
      local original_statusline = trouble_api.statusline
      trouble_api.statusline = function(...)
        -- Wrap the original statusline function to make it more resilient
        local status, result = pcall(original_statusline, ...)
        if status then
          return result
        else
          return "" -- Return empty string on error
        end
      end
    end,
    keys = {
      { "<leader>xx", "<cmd>TroubleToggle<cr>", desc = "Toggle Trouble" },
      { "<leader>xw", "<cmd>TroubleToggle workspace_diagnostics<cr>", desc = "Workspace Diagnostics" },
      { "<leader>xd", "<cmd>TroubleToggle document_diagnostics<cr>", desc = "Document Diagnostics" },
      { "<leader>xl", "<cmd>TroubleToggle loclist<cr>", desc = "Location List" },
      { "<leader>xq", "<cmd>TroubleToggle quickfix<cr>", desc = "Quickfix List" },
    },
  },

  -- UI notifications that look better
  {
    "rcarriga/nvim-notify",
    opts = {
      timeout = 3000,
      max_height = function()
        return math.floor(vim.o.lines * 0.75)
      end,
      max_width = function()
        return math.floor(vim.o.columns * 0.75)
      end,
      render = "wrapped-compact",
      top_down = false, -- Display at the bottom
      background_colour = "#000000",
      stages = "fade",
      icons = {
        ERROR = "󰅙 ",
        WARN = "󰀦 ",
        INFO = "󰋼 ",
        DEBUG = "󰃤 ",
        TRACE = "󰆐 ",
      },
    },
  },
}
