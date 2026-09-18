-- SQL workbench inside nvim — vim-dadbod + dadbod-ui + completion
return {
  {
    "tpope/vim-dadbod",
    dependencies = {
      "kristijanhusak/vim-dadbod-ui",
      "kristijanhusak/vim-dadbod-completion",
    },
    cmd = {
      "DBUI",
      "DBUIToggle",
      "DBUIAddConnection",
      "DBUIFindBuffer",
      "DBUIRenameBuffer",
      "DB",
    },
    init = function()
      vim.g.db_ui_use_nerd_fonts = 1
      vim.g.db_ui_show_database_icon = 1
      vim.g.db_ui_save_location = vim.fn.expand("~/.config/nvim/db_ui")
      vim.g.db_ui_tmp_query_location = vim.fn.expand("~/.config/nvim/db_ui/tmp")
      vim.g.db_ui_execute_on_save = 0      -- don't run on every :w
      vim.g.db_ui_auto_execute_table_helpers = 1
      vim.g.db_ui_winwidth = 35

      -- Hook nvim-cmp into SQL buffers so table/column names autocomplete
      vim.api.nvim_create_autocmd("FileType", {
        pattern = { "sql", "mysql", "plsql" },
        callback = function()
          local ok, cmp = pcall(require, "cmp")
          if ok then
            cmp.setup.buffer({
              sources = {
                { name = "vim-dadbod-completion" },
                { name = "buffer" },
                { name = "path" },
              },
            })
          end
        end,
      })

      -- Optional: pre-configure connections here. Press `A` inside DBUI to add more.
      -- vim.g.dbs = {
      --   scratch = "sqlite:" .. vim.fn.expand("~/scratch.db"),
      --   work    = "postgres://user:pass@localhost:5432/work_dev",
      -- }
    end,
    keys = {
      { "<leader>du", "<cmd>DBUIToggle<cr>",        desc = "DB: toggle UI" },
      { "<leader>dq", "<cmd>DBUI<cr>",              desc = "DB: open UI" },
      { "<leader>df", "<cmd>DBUIFindBuffer<cr>",    desc = "DB: find buffer" },
      { "<leader>dr", "<cmd>DBUIRenameBuffer<cr>",  desc = "DB: rename buffer" },
      { "<leader>da", "<cmd>DBUIAddConnection<cr>", desc = "DB: add connection" },
    },
  },
}
