-- lua/plugins/database.lua
return {
  {
    "tpope/vim-dadbod",
    dependencies = {
      "kristijanhusak/vim-dadbod-ui", -- UI for databases
      "kristijanhusak/vim-dadbod-completion", -- SQL autocompletion
    },
    cmd = { "DBUI", "DBUIToggle", "DBUIAddConnection", "DBUIFindBuffer" },
    config = function()
      -- Register keybindings directly via vim.keymap.set
      vim.keymap.set(
        "n",
        "<leader>St",
        "<cmd>DBUIToggle<cr>",
        { desc = "Toggle Database UI", noremap = true, silent = true }
      )
    end,
  },
}
