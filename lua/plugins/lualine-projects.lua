-- ~/.config/nvim/lua/plugins/lualine-projects.lua
return {
  "nvim-lualine/lualine.nvim",
  event = "VeryLazy",
  opts = function(_, opts)
    -- Function to detect current project
    local function get_project()
      local path = vim.fn.getcwd()

      if string.find(path, "sirens%-backend") then
        return "Sirens Backend"
      elseif string.find(path, "sirens%-frontend") then
        return "Sirens Frontend"
      elseif string.find(path, "fauna%-backend") then
        return "Fauna Backend"
      else
        return "Project: " .. vim.fn.fnamemodify(path, ":t")
      end
    end

    -- Add project info to lualine
    if opts.sections and opts.sections.lualine_c then
      table.insert(opts.sections.lualine_c, {
        get_project,
        icon = "📂",
        color = { fg = "#ff9e64" },
      })
    end

    return opts
  end,
}
