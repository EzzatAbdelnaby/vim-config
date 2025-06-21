-- lua/plugins/telescope-extensions.lua
return {
  {
    "nvim-telescope/telescope.nvim",
    dependencies = {
      -- FZF native for better sorting performance
      { "nvim-telescope/telescope-project.nvim" },
      {
        "nvim-telescope/telescope-fzf-native.nvim",
        build = "make",
        cond = function()
          return vim.fn.executable("make") == 1
        end,
      },
      -- Frecency sorting (combines frequency and recency)
      { "nvim-telescope/telescope-frecency.nvim", dependencies = { "kkharji/sqlite.lua" } },
      -- File browser
      { "nvim-telescope/telescope-file-browser.nvim" },
      -- Project management
      { "nvim-telescope/telescope-project.nvim" },
      -- Media preview
      { "nvim-telescope/telescope-media-files.nvim" },
      -- UI select integration
      { "nvim-telescope/telescope-ui-select.nvim" },
      -- Live grep args for more control
      { "nvim-telescope/telescope-live-grep-args.nvim" },
      -- Better Git integration
      { "tsakirist/telescope-lazy.nvim" },
      -- Advanced symbols search
      { "nvim-telescope/telescope-symbols.nvim" },
      -- Notifications browser
      { "LinArcX/telescope-env.nvim" },
    },
    config = function(_, opts)
      local telescope = require("telescope")
      local actions = require("telescope.actions")
      local action_layout = require("telescope.actions.layout")
      local fb_actions = require("telescope").extensions.file_browser.actions
      local lga_actions = require("telescope-live-grep-args.actions")

      -- Configure and merge custom options with existing
      opts = vim.tbl_deep_extend("force", opts or {}, {
        defaults = {
          prompt_prefix = " ",
          selection_caret = "❯ ",
          path_display = { "truncate" },
          selection_strategy = "reset",
          sorting_strategy = "ascending",
          layout_strategy = "horizontal",
          layout_config = {
            horizontal = {
              prompt_position = "top",
              preview_width = 0.55,
              results_width = 0.8,
            },
            vertical = {
              mirror = false,
            },
            width = 0.85,
            height = 0.80,
            preview_cutoff = 120,
          },
          -- Advanced UI styling
          borderchars = { "─", "│", "─", "│", "╭", "╮", "╯", "╰" },
          color_devicons = true,
          set_env = { ["COLORTERM"] = "truecolor" },

          -- Enhanced keymaps
          mappings = {
            i = {
              -- Navigation keymaps
              ["<C-n>"] = actions.cycle_history_next,
              ["<C-p>"] = actions.cycle_history_prev,
              ["<C-j>"] = actions.move_selection_next,
              ["<C-k>"] = actions.move_selection_previous,

              -- Quick actions
              ["<C-q>"] = actions.smart_send_to_qflist + actions.open_qflist,
              ["<C-l>"] = actions.smart_send_to_loclist + actions.open_loclist,
              ["<C-c>"] = actions.close,
              ["<Esc>"] = actions.close,

              -- Layout control
              ["<M-p>"] = action_layout.toggle_preview,
              ["<M-m>"] = action_layout.toggle_mirror,
              ["<C-space>"] = actions.toggle_selection + actions.move_selection_next,
              ["<S-space>"] = actions.toggle_selection + actions.move_selection_previous,

              -- History control
              ["<Down>"] = actions.move_selection_next,
              ["<Up>"] = actions.move_selection_previous,

              -- Open in different modes
              ["<CR>"] = actions.select_default,
              ["<C-x>"] = actions.select_horizontal,
              ["<C-v>"] = actions.select_vertical,
              ["<C-t>"] = actions.select_tab,

              -- Scroll preview window
              ["<C-u>"] = actions.preview_scrolling_up,
              ["<C-d>"] = actions.preview_scrolling_down,
            },

            n = {
              ["<Esc>"] = actions.close,
              ["q"] = actions.close,

              ["<CR>"] = actions.select_default,
              ["<C-x>"] = actions.select_horizontal,
              ["<C-v>"] = actions.select_vertical,
              ["<C-t>"] = actions.select_tab,

              ["<Tab>"] = actions.toggle_selection + actions.move_selection_next,
              ["<S-Tab>"] = actions.toggle_selection + actions.move_selection_previous,
              ["<C-q>"] = actions.smart_send_to_qflist + actions.open_qflist,
              ["<C-l>"] = actions.smart_send_to_loclist + actions.open_loclist,

              -- Navigation
              ["j"] = actions.move_selection_next,
              ["k"] = actions.move_selection_previous,
              ["H"] = actions.move_to_top,
              ["M"] = actions.move_to_middle,
              ["L"] = actions.move_to_bottom,

              -- Scrolling
              ["<C-u>"] = actions.preview_scrolling_up,
              ["<C-d>"] = actions.preview_scrolling_down,

              -- History navigation
              ["<Down>"] = actions.move_selection_next,
              ["<Up>"] = actions.move_selection_previous,
            },
          },
        },

        -- Configure extensions
        extensions = {
          fzf = {
            fuzzy = true,
            override_generic_sorter = true,
            override_file_sorter = true,
            case_mode = "smart_case",
          },

          file_browser = {
            hijack_netrw = true,
            hidden = true,
            respect_gitignore = true,
            theme = "dropdown",
            mappings = {
              i = {
                ["<C-n>"] = fb_actions.create,
                ["<C-r>"] = fb_actions.rename,
                ["<C-h>"] = fb_actions.goto_parent_dir,
                ["<C-e>"] = fb_actions.goto_home_dir,
                ["<C-w>"] = fb_actions.goto_cwd,
                ["<C-t>"] = fb_actions.change_cwd,
                ["<C-f>"] = fb_actions.toggle_browser,
                ["<C-g>"] = fb_actions.toggle_hidden,
                ["<C-d>"] = fb_actions.remove,
              },
              n = {
                ["n"] = fb_actions.create,
                ["r"] = fb_actions.rename,
                ["h"] = fb_actions.goto_parent_dir,
                ["e"] = fb_actions.goto_home_dir,
                ["w"] = fb_actions.goto_cwd,
                ["t"] = fb_actions.change_cwd,
                ["f"] = fb_actions.toggle_browser,
                ["g"] = fb_actions.toggle_hidden,
                ["d"] = fb_actions.remove,
              },
            },
          },

          media_files = {
            filetypes = { "png", "webp", "jpg", "jpeg", "svg", "pdf" },
            find_cmd = "rg",
          },

          frecency = {
            db_root = vim.fn.stdpath("data") .. "/telescope_frecency.db",
            show_scores = true,
            show_unindexed = true,
            ignore_patterns = { "*.git/*", "*/node_modules/*" },
            disable_devicons = false,
            workspaces = {
              ["conf"] = vim.fn.expand("~/.config"),
              ["data"] = vim.fn.expand("~/.local/share"),
              ["proj"] = vim.fn.expand("~/Projects"),
              ["work"] = vim.fn.expand("~/Work"),
            },
          },

          live_grep_args = {
            auto_quoting = true,
            mappings = {
              i = {
                ["<C-k>"] = lga_actions.quote_prompt(),
                ["<C-i>"] = lga_actions.quote_prompt({ postfix = " --iglob " }),
                ["<C-t>"] = lga_actions.quote_prompt({ postfix = " -t " }),
              },
            },
          },

          -- Use a decent looking UI for vim.ui.select
          ["ui-select"] = {
            require("telescope.themes").get_dropdown({
              borderchars = { "─", "│", "─", "│", "╭", "╮", "╯", "╰" },
              width = 0.8,
              previewer = false,
              prompt_title = false,
              layout_config = {
                horizontal = {
                  width = { padding = 0 },
                  height = { padding = 0 },
                },
              },
            }),
          },
        },

        -- Configure pickers individually
        pickers = {
          find_files = {
            -- Don't follow symbolic links for security
            follow = false,
            -- Search hidden files too (but respect .gitignore)
            hidden = true,
            -- More distinctive file preview
            preview = {
              treesitter = true,
              filesize_limit = 1,
            },
          },

          -- Make buffer search nice
          buffers = {
            show_all_buffers = true,
            sort_lastused = true,
            theme = "dropdown",
            previewer = false,
            mappings = {
              i = {
                ["<C-d>"] = actions.delete_buffer,
              },
              n = {
                ["dd"] = actions.delete_buffer,
              },
            },
          },

          -- Better looking grep
          live_grep = {
            only_sort_text = true,
            additional_args = function()
              return { "--hidden" }
            end,
          },
        },
      })

      -- Setup telescope
      telescope.setup(opts)

      -- Load all the extensions
      telescope.load_extension("fzf")
      telescope.load_extension("file_browser")
      telescope.load_extension("frecency")
      telescope.load_extension("project")
      telescope.load_extension("media_files")
      telescope.load_extension("ui-select")
      telescope.load_extension("live_grep_args")
      telescope.load_extension("lazy")
      telescope.load_extension("env")

      -- Add proper keymaps for all extensions
      local map = vim.keymap.set

      -- File browser
      map("n", "<leader>fb", function()
        require("telescope").extensions.file_browser.file_browser()
      end, { desc = "File Browser" })

      -- List recent files using frecency algorithm
      map("n", "<leader>fr", function()
        require("telescope").extensions.frecency.frecency()
      end, { desc = "Recent Files (Frecency)" })

      -- Enhanced live-grep with arguments
      map("n", "<leader>fa", function()
        require("telescope").extensions.live_grep_args.live_grep_args()
      end, { desc = "Live Grep with Args" })

      -- Media files preview
      map("n", "<leader>fm", function()
        require("telescope").extensions.media_files.media_files()
      end, { desc = "Media Files" })

      -- Environment variables
      map("n", "<leader>fen", function()
        require("telescope").extensions.env.env()
      end, { desc = "Environment Variables" })

      -- Emoji picker
      map("n", "<leader>fe", function()
        require("telescope").extensions.symbols.symbols({ symbols = { "emoji" } })
      end, { desc = "Emoji Picker" })

      -- Symbol picker
      map("n", "<leader>fs", function()
        require("telescope").extensions.symbols.symbols({ symbols = { "math", "greek", "arrows" } })
      end, { desc = "Symbol Picker" })

      -- List lazy.nvim plugins
      map("n", "<leader>fl", function()
        require("telescope").extensions.lazy.lazy()
      end, { desc = "List Plugins" })

      -- Resume last picker with last results
      map("n", "<leader>fR", function()
        require("telescope.builtin").resume()
      end, { desc = "Resume Last Search" })
    end,
  },
}
