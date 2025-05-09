-- lua/plugins/harpoon.lua
return {
  {
    "ThePrimeagen/harpoon",
    branch = "harpoon2", -- Use harpoon v2
    dependencies = { "nvim-lua/plenary.nvim" },
    event = "VeryLazy",
    config = function()
      local harpoon = require("harpoon")

      -- REQUIRED
      harpoon:setup({
        settings = {
          save_on_toggle = true,
          sync_on_ui_close = true,
          key = function()
            -- Get a stable identifier for the current project
            return vim.loop.cwd()
          end,
        },
        -- UI appearance
        menu = {
          width = math.floor(vim.api.nvim_win_get_width(0) * 0.7),
          height = 10,
          border_chars = { "─", "│", "─", "│", "╭", "╮", "╯", "╰" },
        },
      })

      -- Keymaps
      local function map(mode, lhs, rhs, desc)
        vim.keymap.set(mode, lhs, rhs, { silent = true, desc = desc })
      end

      -- Add file to harpoon
      map("n", "<leader>ha", function()
        harpoon:list():append()
      end, "Harpoon Add File")

      -- Toggle the harpoon quick menu
      map("n", "<leader>hm", function()
        harpoon.ui:toggle_quick_menu(harpoon:list())
      end, "Harpoon Menu")

      -- Quick navigation to harpoon'd files
      -- Jump to the first 4 files
      map("n", "<leader>h1", function()
        harpoon:list():select(1)
      end, "Harpoon File 1")
      map("n", "<leader>h2", function()
        harpoon:list():select(2)
      end, "Harpoon File 2")
      map("n", "<leader>h3", function()
        harpoon:list():select(3)
      end, "Harpoon File 3")
      map("n", "<leader>h4", function()
        harpoon:list():select(4)
      end, "Harpoon File 4")

      -- Navigate to next and previous harpoon'd files
      map("n", "<leader>hn", function()
        harpoon:list():next()
      end, "Harpoon Next File")
      map("n", "<leader>hp", function()
        harpoon:list():prev()
      end, "Harpoon Prev File")

      -- Extra useful keys
      map("n", "<leader>hc", function()
        harpoon:list():clear()
      end, "Harpoon Clear All")
      map("n", "<leader>hr", function()
        harpoon:list():remove()
      end, "Harpoon Remove Current")

      -- Telescope integration if available
      if package.loaded["telescope"] then
        local conf = require("telescope.config").values
        local function toggle_telescope(harpoon_files)
          local file_paths = {}
          for _, item in ipairs(harpoon_files.items) do
            table.insert(file_paths, item.value)
          end

          require("telescope.pickers")
            .new({}, {
              prompt_title = "Harpoon",
              finder = require("telescope.finders").new_table({
                results = file_paths,
              }),
              previewer = conf.file_previewer({}),
              sorter = conf.generic_sorter({}),
            })
            :find()
        end

        -- Open harpoon marks in Telescope
        map("n", "<leader>hf", function()
          toggle_telescope(harpoon:list())
        end, "Harpoon Files in Telescope")
      end
    end,
  },
}
