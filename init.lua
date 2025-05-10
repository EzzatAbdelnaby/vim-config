-- bootstrap lazy.nvim, LazyVim and your plugins
require("config.lazy")

-- Load autocmds
-- Load custom autocmds for TypeScript
require("config.autocmds-typescript")

-- Load custom autocmds for React
require("config.autocmds-react")
-- if vim.fn.argc() == 0 and #vim.api.nvim_list_tabpages() == 1 then
--   require("workspace-tabs").setup()
-- end
