return {
  -- Statusline
  {
    "nvim-lualine/lualine.nvim",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    config = function()
      require("lualine").setup({
        options = {
          theme = "rose-pine",
          component_separators = { left = "|", right = "|" },
          section_separators = { left = "", right = "" },
          globalstatus = true,
          refresh = {
            statusline = 100, -- Slower refresh, no animation
          },
        },
        sections = {
          lualine_a = { "mode" },
          lualine_b = { "branch", "diff", "diagnostics" },
          lualine_c = { "filename" },
          lualine_x = { "encoding", "fileformat", "filetype" },
          lualine_y = { "progress" },
          lualine_z = { "location" },
        },
      })
    end,
  },

  -- File explorer - Neo-tree
  {
    "nvim-neo-tree/neo-tree.nvim",
    branch = "v3.x",
    dependencies = {
      "nvim-lua/plenary.nvim",
      "nvim-tree/nvim-web-devicons",
      "MunifTanjim/nui.nvim",
    },
    config = function()
      -- Disable netrw
      vim.g.loaded_netrw = 1
      vim.g.loaded_netrwPlugin = 1

      require("neo-tree").setup({
        close_if_last_window = true,
        popup_border_style = "rounded",
        enable_git_status = true,
        enable_diagnostics = true,
        sort_case_insensitive = true,
        default_component_configs = {
          indent = {
            indent_size = 2,
            padding = 1,
            with_markers = true,
            indent_marker = "│",
            last_indent_marker = "└",
            with_expanders = true,
            expander_collapsed = "",
            expander_expanded = "",
          },
          icon = {
            folder_closed = "",
            folder_open = "",
            folder_empty = "",
          },
          modified = {
            symbol = "●",
          },
          git_status = {
            symbols = {
              added = "✚",
              modified = "",
              deleted = "✖",
              renamed = "󰁕",
              untracked = "",
              ignored = "",
              unstaged = "󰄱",
              staged = "",
              conflict = "",
            },
          },
        },
        window = {
          position = "left",
          width = 35,
          mappings = {
            ["<space>"] = "none", -- Disable space (we use it as leader)
            ["<cr>"] = "open",
            ["o"] = "open",
            ["s"] = "open_split",
            ["v"] = "open_vsplit",
            ["t"] = "open_tabnew",
            ["a"] = "add",
            ["d"] = "delete",
            ["r"] = "rename",
            ["c"] = "copy",
            ["m"] = "move",
            ["q"] = "close_window",
            ["R"] = "refresh",
            ["?"] = "show_help",
            ["<"] = "prev_source",
            [">"] = "next_source",
            ["/"] = "fuzzy_finder",
            ["f"] = "filter_on_submit",
            ["<C-x>"] = "clear_filter",
            ["P"] = { "toggle_preview", config = { use_float = true } },
          },
        },
        filesystem = {
          filtered_items = {
            visible = false,
            hide_dotfiles = false,
            hide_gitignored = false,
            hide_by_name = {
              ".git",
              "node_modules",
              ".cache",
            },
          },
          follow_current_file = {
            enabled = true,          -- Auto-reveal current file
            leave_dirs_open = true,  -- Keep folders open
          },
          use_libuv_file_watcher = true, -- Auto-refresh on file changes
        },
        buffers = {
          follow_current_file = {
            enabled = true,
          },
          show_unloaded = true,
        },
        git_status = {
          window = {
            position = "float",
          },
        },
      })

      -- Keymaps
      vim.keymap.set("n", "<leader>e", "<cmd>Neotree toggle reveal<CR>", { desc = "Explorer (reveal file)" })
      vim.keymap.set("n", "<leader>E", "<cmd>Neotree toggle<CR>", { desc = "Explorer (toggle)" })
      vim.keymap.set("n", "<leader>eb", "<cmd>Neotree toggle buffers<CR>", { desc = "Explorer buffers" })
      vim.keymap.set("n", "<leader>eg", "<cmd>Neotree toggle git_status<CR>", { desc = "Explorer git status" })
    end,
  },

  -- Bufferline (NO ANIMATIONS)
  {
    "akinsho/bufferline.nvim",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    version = "*",
    config = function()
      require("bufferline").setup({
        options = {
          mode = "buffers",
          themable = true,
          numbers = "none",
          close_command = "bdelete! %d",
          right_mouse_command = "bdelete! %d",
          left_mouse_command = "buffer %d",
          indicator = {
            icon = "▎",
            style = "icon",
          },
          buffer_close_icon = "×",
          modified_icon = "●",
          close_icon = "×",
          left_trunc_marker = "",
          right_trunc_marker = "",
          diagnostics = "nvim_lsp",
          diagnostics_indicator = function(count, level)
            local icon = level:match("error") and " " or " "
            return " " .. icon .. count
          end,
          offsets = {
            {
              filetype = "neo-tree",
              text = "File Explorer",
              text_align = "center",
              separator = true,
            },
          },
          separator_style = "thin",
          enforce_regular_tabs = false,
          always_show_bufferline = true,
          show_buffer_close_icons = true,
          show_close_icon = false,
          show_tab_indicators = true,
          persist_buffer_sort = true,
          -- NO ANIMATIONS
          animation = false,
        },
      })

      -- Keymaps
      vim.keymap.set("n", "<S-h>", "<cmd>BufferLineCyclePrev<CR>", { desc = "Previous buffer" })
      vim.keymap.set("n", "<S-l>", "<cmd>BufferLineCycleNext<CR>", { desc = "Next buffer" })
      vim.keymap.set("n", "<leader>bp", "<cmd>BufferLinePick<CR>", { desc = "Pick buffer" })
      vim.keymap.set("n", "<leader>bc", "<cmd>BufferLinePickClose<CR>", { desc = "Pick close buffer" })
    end,
  },

  -- Indent guides (NO ANIMATIONS)
  {
    "lukas-reineke/indent-blankline.nvim",
    main = "ibl",
    event = { "BufReadPost", "BufNewFile" },
    config = function()
      require("ibl").setup({
        indent = {
          char = "│",
        },
        scope = {
          enabled = true,
          show_start = false,
          show_end = false,
        },
      })
    end,
  },

  -- Icons
  {
    "nvim-tree/nvim-web-devicons",
    config = function()
      require("nvim-web-devicons").setup({
        default = true,
      })
    end,
  },

  -- Better UI for inputs and selects (NO ANIMATIONS)
  {
    "stevearc/dressing.nvim",
    event = "VeryLazy",
    config = function()
      require("dressing").setup({
        input = {
          enabled = true,
          default_prompt = "Input:",
          border = "rounded",
        },
        select = {
          enabled = true,
          backend = { "telescope", "builtin" },
          builtin = {
            border = "rounded",
          },
        },
      })
    end,
  },

  -- Which-key (shows keybindings) - NO ANIMATIONS
  {
    "folke/which-key.nvim",
    event = "VeryLazy",
    config = function()
      require("which-key").setup({
        preset = "classic",
        -- NO ANIMATIONS
        delay = 0,
        win = {
          border = "rounded",
        },
      })
    end,
  },
}
