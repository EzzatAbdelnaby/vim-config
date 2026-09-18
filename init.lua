-- Main entry point for Neovim configuration
-- Bootstrap lazy.nvim and load all configurations

-- Load core options
require("config.options")

-- Load keymaps
require("config.keymaps")

-- Load lazy.nvim (plugin manager)
-- (colorscheme is set by the rose-pine plugin's own config() in
-- lua/plugins/colorscheme.lua, which also applies custom highlight
-- overrides — do not call :colorscheme again here, it would re-source
-- the base palette and wipe those overrides)
require("config.lazy")

-- Load custom review mode
require("config.review")

-- Load PR review mode
require("config.pr-review")

-- Load Confluence integration
require("config.confluence")

-- Load Jira integration
require("config.jira")

-- Load Docs reader (:Docs <url> -> any web docs as markdown in nvim)
require("config.docs")


-- Claude Code integration is now provided by the official `claudecode.nvim`
-- plugin (see lua/plugins/claudecode.lua). Skills live in ~/.claude/skills/.
