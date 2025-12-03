-- Main entry point for Neovim configuration
-- Bootstrap lazy.nvim and load all configurations

-- Load core options
require("config.options")

-- Load keymaps
require("config.keymaps")

-- Load lazy.nvim (plugin manager)
require("config.lazy")
