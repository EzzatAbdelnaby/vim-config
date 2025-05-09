-- ~/.config/nvim/lua/project-terminals.lua
local M = {}

-- Initialize project terminals based on current tab
function M.setup()
  -- Load toggleterm if not already loaded
  if not package.loaded["toggleterm"] then
    require("toggleterm").setup()
  end

  local Terminal = require("toggleterm.terminal").Terminal

  -- Create terminals based on current directory
  local function create_terminal_for_current_tab(tab)
    local cwd = vim.fn.getcwd()
    local id, name, cmd

    if cwd:match("sirens%-backend") then
      id = "sirens_backend"
      name = "Sirens-Backend"
      cmd = "cd " .. cwd .. " && npm run dev"
    elseif cwd:match("sirens%-frontend") then
      id = "sirens_frontend"
      name = "Sirens-Frontend"
      cmd = "cd " .. cwd .. " && npm run dev"
    elseif cwd:match("fauna%-backend") then
      id = "fauna_backend"
      name = "Fauna-Backend"
      cmd = "cd " .. cwd .. " && npm run dev"
    else
      id = "tab_" .. tab
      name = "Terminal-" .. tab
      cmd = "cd " .. cwd
    end

    -- Create a dedicated terminal for this tab
    local term = Terminal:new({
      cmd = cmd,
      hidden = true,
      direction = "float", -- or "horizontal", "vertical" based on preference
      float_opts = {
        border = "curved",
        width = 100,
        height = 20,
        winblend = 3,
      },
      on_open = function(term)
        -- Customize terminal behavior on open
        vim.cmd("startinsert!")
        vim.api.nvim_buf_set_keymap(term.bufnr, "t", "<Esc>", "<C-\\><C-n>", { noremap = true, silent = true })
      end,
    })

    return { id = id, term = term }
  end

  -- Create terminals for all tabs
  local tabs = {}
  local current_tab = vim.fn.tabpagenr()

  for i = 1, vim.fn.tabpagenr("$") do
    vim.cmd(i .. "tabnext")
    local term_info = create_terminal_for_current_tab(i)
    tabs[i] = term_info

    -- Store in global state
    _G[term_info.id .. "_term"] = term_info.term

    -- Create toggle function
    _G["toggle_" .. term_info.id] = function()
      term_info.term:toggle()
    end
  end

  -- Go back to original tab
  vim.cmd(current_tab .. "tabnext")

  -- Set keybindings for tab-specific terminals
  vim.keymap.set("n", "<leader>tt", function()
    local tab = vim.fn.tabpagenr()
    if tabs[tab] then
      _G["toggle_" .. tabs[tab].id]()
    end
  end, { desc = "Toggle Terminal for Current Tab" })

  -- Specific project terminals
  vim.keymap.set("n", "<leader>1t", function()
    if _G.toggle_sirens_backend then
      _G.toggle_sirens_backend()
    end
  end, { desc = "Toggle Sirens Backend Terminal" })

  vim.keymap.set("n", "<leader>2t", function()
    if _G.toggle_sirens_frontend then
      _G.toggle_sirens_frontend()
    end
  end, { desc = "Toggle Sirens Frontend Terminal" })

  vim.keymap.set("n", "<leader>3t", function()
    if _G.toggle_fauna_backend then
      _G.toggle_fauna_backend()
    end
  end, { desc = "Toggle Fauna Backend Terminal" })

  -- Keybindings for tab navigation
  vim.keymap.set("n", "<leader>1", "1gt", { desc = "Go to tab 1 (Sirens Backend)" })
  vim.keymap.set("n", "<leader>2", "2gt", { desc = "Go to tab 2 (Sirens Frontend)" })
  vim.keymap.set("n", "<leader>3", "3gt", { desc = "Go to tab 3 (Fauna Backend)" })
end

return M
