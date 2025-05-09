-- ~/.config/nvim/lua/plugins/project-switcher.lua
return {
  "nvim-telescope/telescope.nvim",
  keys = {
    {
      "<leader>fp",
      function()
        local actions = require("telescope.actions")
        local action_state = require("telescope.actions.state")

        -- Define your projects
        local projects = {
          { "Sirens Backend", "/Users/mac/Work/Nawy/sirens-backend", 1 },
          { "Sirens Frontend", "/Users/mac/Work/Nawy/sirens-frontend", 2 },
          { "Fauna Backend", "/Users/mac/Work/Nawy/fauna-backend", 3 },
        }

        require("telescope.pickers")
          .new({}, {
            prompt_title = "Switch Project",
            finder = require("telescope.finders").new_table({
              results = projects,
              entry_maker = function(entry)
                return {
                  value = entry,
                  display = entry[1],
                  ordinal = entry[1],
                }
              end,
            }),
            sorter = require("telescope.config").values.generic_sorter({}),
            attach_mappings = function(prompt_bufnr, map)
              actions.select_default:replace(function()
                local selection = action_state.get_selected_entry()
                actions.close(prompt_bufnr)

                -- Switch to the selected project tab
                vim.cmd(selection.value[3] .. "tabnext")

                -- Change directory to the project
                vim.cmd("cd " .. selection.value[2])

                -- Notify the user
                vim.notify("Switched to " .. selection.value[1], vim.log.levels.INFO)
              end)
              return true
            end,
          })
          :find()
      end,
      desc = "Switch Project",
    },
  },
}
