return {
  {
    "aurum77/live-server.nvim",
    build = function()
      require("live_server.util").install()
    end,
    cmd = { "LiveServerStart", "LiveServerStop" },
    config = function()
      local status_ok, live_server = pcall(require, "live_server")
      if status_ok then
        live_server.setup({})
      end
    end,
    keys = {
      { "<leader>ls", "<cmd>LiveServerStart<CR>", desc = "Start Live Server" },
      { "<leader>lx", "<cmd>LiveServerStop<CR>", desc = "Stop Live Server" },
    },
  },
}
