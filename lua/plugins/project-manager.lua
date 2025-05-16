-- ~/.config/nvim/lua/plugins/project-manager.lua
return {
  {
    "nvim-telescope/telescope.nvim",
    dependencies = {
      { "nvim-telescope/telescope-fzf-native.nvim", build = "make" },
      { "nvim-telescope/telescope-project.nvim" },
    },
    keys = {
      -- Add quick project switching keybinding
      {
        "<leader>fp",
        "<cmd>Telescope project<CR>",
        desc = "Find Project",
      },
      -- Quick switch to specific projects
      {
        "<leader>pf",
        function()
          -- Switch to fauna-backend
          require("telescope.builtin").find_files({ cwd = "/Users/mac/Work/Nawy/fauna-backend" })
        end,
        desc = "Fauna Backend Files",
      },
      {
        "<leader>ps",
        function()
          -- Switch to sirens-backend
          require("telescope.builtin").find_files({ cwd = "/Users/mac/Work/Nawy/sirens-backend" })
        end,
        desc = "Sirens Backend Files",
      },
      {
        "<leader>pF",
        function()
          -- Switch to sirens-frontend
          require("telescope.builtin").find_files({ cwd = "/Users/mac/Work/Nawy/sirens-frontend" })
        end,
        desc = "Sirens Frontend Files",
      },
    },
    config = function(_, opts)
      -- Load telescope and its extensions
      local telescope = require("telescope")
      telescope.setup(opts)
      telescope.load_extension("fzf")
      telescope.load_extension("project")

      -- Configure project extension
      telescope.extensions.project.project = {
        base_dirs = {
          { path = "/Users/mac/Work/Nawy/fauna-backend", max_depth = 1 },
          { path = "/Users/mac/Work/Nawy/sirens-backend", max_depth = 1 },
          { path = "/Users/mac/Work/Nawy/sirens-frontend", max_depth = 1 },
        },
        hidden_files = true,
        theme = "dropdown",
        order_by = "recent",
        sync_with_nvim_tree = true,
      }
    end,
  },

  -- Add project detection to lualine
  {
    "nvim-lualine/lualine.nvim",
    event = "VeryLazy",
    opts = function(_, opts)
      -- Function to detect current project
      local function get_project()
        local path = vim.fn.getcwd()

        if string.find(path, "fauna%-backend") then
          return "🦊 Fauna Backend"
        elseif string.find(path, "sirens%-backend") then
          return "🚨 Sirens Backend"
        elseif string.find(path, "sirens%-frontend") then
          return "🖥️ Sirens Frontend"
        else
          return "📂 " .. vim.fn.fnamemodify(path, ":t")
        end
      end

      -- Add project info to lualine
      if opts.sections and opts.sections.lualine_a then
        table.insert(opts.sections.lualine_a, {
          get_project,
          color = { gui = "bold" },
        })
      end

      return opts
    end,
  },

  -- Configure harpoon for per-project marks
  {
    "ThePrimeagen/harpoon",
    branch = "harpoon2",
    dependencies = { "nvim-lua/plenary.nvim" },
    config = function()
      local harpoon = require("harpoon")

      harpoon:setup({
        settings = {
          save_on_toggle = true,
          sync_on_ui_close = true,
          key = function()
            -- Get unique key for current project
            local path = vim.loop.cwd()
            -- Extract project name for the key
            local project_name = vim.fn.fnamemodify(path, ":t")
            return project_name
          end,
        },
      })

      -- Harpoon keymaps
      vim.keymap.set("n", "<leader>ha", function()
        harpoon:list():append()
      end, { desc = "Add file to Harpoon" })

      vim.keymap.set("n", "<leader>hh", function()
        harpoon.ui:toggle_quick_menu(harpoon:list())
      end, { desc = "Show Harpoon menu" })

      -- Quick access to marked files
      for i = 1, 4 do
        vim.keymap.set("n", "<leader>h" .. i, function()
          harpoon:list():select(i)
        end, { desc = "Harpoon buffer " .. i })
      end
    end,
  },

  -- Auto-setup project-specific settings based on directory
  {
    "LazyVim/LazyVim",
    opts = function()
      -- Set up auto commands for project-specific settings
      vim.api.nvim_create_augroup("ProjectSpecificSettings", { clear = true })

      -- Fauna Backend settings
      vim.api.nvim_create_autocmd("DirChanged", {
        group = "ProjectSpecificSettings",
        pattern = "*",
        callback = function()
          local path = vim.fn.getcwd()

          if string.find(path, "fauna%-backend") then
            -- Set fauna-backend specific settings
            vim.opt.tabstop = 4
            vim.opt.shiftwidth = 4
            vim.opt.expandtab = true
            vim.g.current_project = "fauna-backend"

            -- Notify user
            vim.notify("Loaded fauna-backend settings", vim.log.levels.INFO)
          elseif string.find(path, "sirens%-backend") then
            -- Set sirens-backend specific settings
            vim.opt.tabstop = 4
            vim.opt.shiftwidth = 4
            vim.opt.expandtab = true
            vim.g.current_project = "sirens-backend"

            -- Notify user
            vim.notify("Loaded sirens-backend settings", vim.log.levels.INFO)
          elseif string.find(path, "sirens%-frontend") then
            -- Set sirens-frontend specific settings
            vim.opt.tabstop = 2
            vim.opt.shiftwidth = 2
            vim.opt.expandtab = true
            vim.g.current_project = "sirens-frontend"

            -- Notify user
            vim.notify("Loaded sirens-frontend settings", vim.log.levels.INFO)
          end
        end,
      })
    end,
  },
}
