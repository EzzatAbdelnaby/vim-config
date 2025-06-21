return {
  {
    "prisma/vim-prisma",
  },
  {
    "neovim/nvim-lspconfig",
    config = function()
      -- Ensure file type detection
      vim.filetype.add({
        extension = {
          prisma = "prisma",
        },
      })

      -- Set up LSP when Prisma file is opened
      vim.api.nvim_create_autocmd("FileType", {
        pattern = "prisma",
        callback = function()
          local lspconfig = require("lspconfig")

          -- Check if already attached
          local clients = vim.lsp.get_active_clients({ name = "prismals" })
          if #clients > 0 then
            return
          end

          lspconfig.prismals.setup({
            cmd = { "prisma-language-server", "--stdio" },
            filetypes = { "prisma" },
            root_dir = function(fname)
              return lspconfig.util.find_git_ancestor(fname) or vim.fn.getcwd()
            end,
            settings = {
              prisma = {
                format = true,
              },
            },
            on_attach = function(client, bufnr)
              print("Prisma LSP attached to buffer " .. bufnr)
            end,
          })

          -- Start the LSP
          vim.cmd("LspStart prismals")
        end,
      })
    end,
  },
}
