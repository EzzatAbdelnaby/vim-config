-- Kitty Terminal Reference
-- This file documents your Kitty terminal settings for quick reference
-- Location: ~/.config/kitty/kitty.conf

--[[
================================================================================
                            KITTY TERMINAL SETTINGS
================================================================================

FONT
----
  Font:         FiraCode Nerd Font Mono
  Size:         12.0
  Features:     Ligatures (+liga +calt)

APPEARANCE
----------
  Background:   Semi-transparent (0.85 opacity)
  Cursor:       Block, blinking (0.6s interval)
  Tab bar:      Top, powerline style (slanted)
  Colors:       Gruvbox Dark with green tint

TAB KEYBINDINGS
---------------
  Cmd + 1-9     Go to tab 1-9
  Cmd + W       Close current tab
  Cmd + T       New tab (default)
  Cmd + Enter   Toggle fullscreen

COPY/PASTE
----------
  Ctrl+Shift+C  Copy to clipboard
  Ctrl+Shift+V  Paste from clipboard
  Select text   Auto-copy (copy_on_select)

TAB BAR COLORS
--------------
  Active:       Green background (#98971a), dark text
  Inactive:     Dark background (#3c3836), gray text

COLOR SCHEME (Gruvbox Dark)
---------------------------
  Background:   #282b26
  Foreground:   #ebdbb2

  Black:        #282828 / #928374
  Red:          #cc241d / #fb4934
  Green:        #98971a / #b8bb26
  Yellow:       #d79921 / #fabd2f
  Blue:         #458588 / #83a598
  Magenta:      #b16286 / #d3869b
  Cyan:         #689d6a / #8ec07c
  White:        #a89984 / #ebdbb2

USEFUL COMMANDS
---------------
  kitty +kitten themes     Browse and apply themes
  kitty --debug-config     Debug configuration
  kitty +list-fonts        List available fonts

RELOAD CONFIG
-------------
  Ctrl+Shift+F5   Reload kitty.conf (default)

  Or close and reopen Kitty

================================================================================
]]

-- You can add Kitty-related functions here if needed
local M = {}

-- Open Kitty config in nvim
M.edit_kitty_config = function()
  vim.cmd("edit ~/.config/kitty/kitty.conf")
end

-- Reload Kitty (sends signal)
M.reload_kitty = function()
  vim.fn.system("kill -SIGUSR1 $(pgrep kitty)")
  vim.notify("Kitty config reloaded", vim.log.levels.INFO)
end

-- Keymaps (optional - uncomment if you want these)
-- vim.keymap.set("n", "<leader>ck", M.edit_kitty_config, { desc = "Edit Kitty config" })
-- vim.keymap.set("n", "<leader>cK", M.reload_kitty, { desc = "Reload Kitty config" })

return M
