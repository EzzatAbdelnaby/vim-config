-- ~/.config/nvim/lua/plugins/terminal.lua
return {
  -- Use toggleterm for better terminal integration
  {
    "akinsho/toggleterm.nvim",
    version = "*",
    config = function()
      require("toggleterm").setup({
        -- Size can be a number or function
        size = function(term)
          if term.direction == "horizontal" then
            return 15 -- Height of horizontal terminal
          elseif term.direction == "vertical" then
            return vim.o.columns * 0.4 -- Width of vertical terminal
          end
        end,
        open_mapping = [[<c-\>]], -- Use Ctrl+\ to toggle terminal
        hide_numbers = true, -- Hide line numbers
        shade_filetypes = {},
        shade_terminals = true,
        shading_factor = 2, -- Degree of shading (dark/light)
        start_in_insert = true, -- Start terminal in insert mode
        insert_mappings = true, -- Apply mappings in insert mode
        terminal_mappings = true, -- Apply mappings in terminal mode
        persist_size = true,
        direction = "horizontal", -- Open horizontally (at bottom)
        close_on_exit = true, -- Close terminal when process exits
        shell = vim.o.shell, -- Shell to use
        float_opts = {
          border = "curved", -- Border for floating terminal
          winblend = 0,
          highlights = {
            border = "Normal",
            background = "Normal",
          },
        },
      })

      -- Add custom keybindings
      local keymap = vim.keymap.set
      local opts = { noremap = true, silent = true }

      -- Open horizontal terminal at bottom
      keymap("n", "<leader>th", "<cmd>ToggleTerm direction=horizontal<CR>", opts)

      -- Open vertical terminal on right
      keymap("n", "<leader>tv", "<cmd>ToggleTerm direction=vertical<CR>", opts)

      -- Open floating terminal
      keymap("n", "<leader>tf", "<cmd>ToggleTerm direction=float<CR>", opts)

      -- Quickly exit terminal mode with Esc
      keymap("t", "<Esc>", "<C-\\><C-n>", opts)

      -- Function to open lazygit in terminal
      keymap(
        "n",
        "<leader>tg",
        "<cmd>lua require('toggleterm.terminal').Terminal:new({cmd='lazygit', direction='float'}):toggle()<CR>",
        opts
      )
    end,
  },
}
