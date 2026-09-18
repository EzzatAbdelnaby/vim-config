-- claudecode.nvim — official MCP protocol bridge to Claude Code CLI
return {
  {
    "coder/claudecode.nvim",
    dependencies = { "folke/snacks.nvim" },
    config = function(_, opts)
      require("claudecode").setup(opts)

      -- ── Preserve scroll position when leaving/returning to the Claude terminal ──
      -- snacks.nvim's terminal auto_insert is hardcoded on in claudecode.nvim,
      -- which snaps the cursor to the bottom every time the window regains focus.
      -- Save the cursor row on WinLeave; if we re-enter and the user wasn't at
      -- the bottom, kick out of insert mode and restore the saved row.
      local claude_pos = {}
      local function is_claude_terminal(buf)
        if vim.bo[buf].buftype ~= "terminal" then return false end
        local name = vim.api.nvim_buf_get_name(buf)
        return name:lower():match("claude") ~= nil
      end

      local aug = vim.api.nvim_create_augroup("ClaudeCodeScrollKeep", { clear = true })
      vim.api.nvim_create_autocmd("WinLeave", {
        group = aug,
        callback = function()
          local buf = vim.api.nvim_get_current_buf()
          if is_claude_terminal(buf) then
            claude_pos[buf] = vim.api.nvim_win_get_cursor(0)
          end
        end,
      })
      vim.api.nvim_create_autocmd({ "BufEnter", "WinEnter" }, {
        group = aug,
        callback = function()
          vim.defer_fn(function()
            local buf = vim.api.nvim_get_current_buf()
            if not is_claude_terminal(buf) then return end
            local pos = claude_pos[buf]
            if not pos then return end
            local lc = vim.api.nvim_buf_line_count(buf)
            -- Only restore if the user had genuinely scrolled away from the bottom
            if pos[1] < lc - 2 then
              vim.cmd("stopinsert")
              pcall(vim.api.nvim_win_set_cursor, 0, pos)
            end
          end, 80)
        end,
      })
    end,
    keys = {
      { "<leader>a",  nil,                              desc = "AI / Claude Code" },
      { "<leader>ac", "<cmd>ClaudeCode<cr>",            desc = "Toggle Claude" },
      { "<leader>af", "<cmd>ClaudeCodeFocus<cr>",       desc = "Focus Claude" },
      { "<leader>ar", "<cmd>ClaudeCode --resume<cr>",   desc = "Resume Claude" },
      { "<leader>aC", "<cmd>ClaudeCode --continue<cr>", desc = "Continue Claude" },
      { "<leader>am", "<cmd>ClaudeCodeSelectModel<cr>", desc = "Select model" },
      { "<leader>ab", "<cmd>ClaudeCodeAdd %<cr>",       desc = "Add current buffer" },
      { "<leader>as", "<cmd>ClaudeCodeSend<cr>", mode = "v", desc = "Send selection" },
      {
        "<leader>as",
        "<cmd>ClaudeCodeTreeAdd<cr>",
        desc = "Add file from tree",
        ft = { "NvimTree", "neo-tree", "oil", "minifiles", "netrw" },
      },
      -- Diff workflow
      { "<leader>aa", "<cmd>ClaudeCodeDiffAccept<cr>", desc = "Accept diff" },
      { "<leader>ad", "<cmd>ClaudeCodeDiffDeny<cr>",   desc = "Deny diff" },
    },
  },
}
