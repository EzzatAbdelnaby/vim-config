-- lua/plugins/which-key-groups.lua
return {
  {
    "folke/which-key.nvim",
    config = function(_, opts)
      local wk = require("which-key")

      -- Register key groups using the register function
      wk.register({
        ["<leader>d"] = { name = "+debug" },
        ["<leader>S"] = { name = "+database" },
        ["<leader>w"] = { name = "+windows" },
        ["<leader>q"] = { name = "+quit/session" },
        ["<leader>x"] = { name = "+diagnostics/quickfix" },
        ["<leader>D"] = { name = "+docker" },
      })

      -- Register Docker commands
      wk.register({
        ["<leader>Di"] = { "<cmd>terminal docker images<cr>", "Docker Images" },
        ["<leader>Dc"] = { "<cmd>terminal docker-compose up -d<cr>", "Docker Compose Up" },
        ["<leader>Db"] = { "<cmd>terminal docker build .<cr>", "Docker Build" },
        ["<leader>Dr"] = { "<cmd>terminal docker run<cr>", "Docker Run" },
        ["<leader>Dp"] = { "<cmd>terminal docker ps<cr>", "Docker PS" },
      })
    end,
  },
}
