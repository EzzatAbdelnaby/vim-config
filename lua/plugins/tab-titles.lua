-- ~/.config/nvim/lua/plugins/tab-titles.lua
return {
  "LazyVim/LazyVim",
  config = function()
    -- Function to set tab titles based on directory
    local function set_tab_titles()
      local tabnr = vim.fn.tabpagenr()
      local tabcount = vim.fn.tabpagenr("$")

      for i = 1, tabcount do
        vim.cmd(i .. "tabnext")
        local cwd = vim.fn.getcwd()
        local title = "Unknown"

        if cwd:match("sirens%-backend") then
          title = "Sirens Backend"
        elseif cwd:match("sirens%-frontend") then
          title = "Sirens Frontend"
        elseif cwd:match("fauna%-backend") then
          title = "Fauna Backend"
        else
          -- Extract last directory name
          title = vim.fn.fnamemodify(cwd, ":t")
        end

        -- Set title for this tab
        vim.opt_local.titlestring = title
        vim.t.custom_title = title
      end

      -- Go back to original tab
      vim.cmd(tabnr .. "tabnext")
    end

    -- Set tab titles on startup and when changing directories
    vim.api.nvim_create_autocmd({ "TabNew", "DirChanged" }, {
      callback = function()
        set_tab_titles()
      end,
    })

    -- Initial setup
    vim.defer_fn(set_tab_titles, 100)
  end,
}
