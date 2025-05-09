-- ~/.config/nvim/lua/plugins/neotree-tabs.lua
return {
  "nvim-neo-tree/neo-tree.nvim",
  opts = {
    close_if_last_window = true,
    enable_git_status = true,
    enable_diagnostics = true,

    -- This fixes the neo-tree buffer behavior across tabs
    filesystem = {
      follow_current_file = {
        enabled = true,
        leave_dirs_open = true,
      },
      use_libuv_file_watcher = true,
      bind_to_cwd = false, -- This is important for tab-specific directories
      cwd_target = {
        sidebar = "tab", --Make neo-tree use tab-local directory
      },
    },
  },
  keys = {
    -- Add this key to force directory refresh
    {
      "<leader>ft",
      function()
        vim.cmd("Neotree reveal")
      end,
      desc = "Reveal file in tree",
    },
  },
}
