-- Prisma configuration
return {
  -- Prisma LSP
  {
    "neovim/nvim-lspconfig",
    opts = function(_, opts)
      local capabilities = require("cmp_nvim_lsp").default_capabilities()

      local on_attach = function(client, bufnr)
        local keymap_opts = { buffer = bufnr, silent = true }
        vim.keymap.set("n", "gR", "<cmd>Telescope lsp_references<CR>", keymap_opts)
        vim.keymap.set("n", "gD", vim.lsp.buf.declaration, keymap_opts)
        vim.keymap.set("n", "gd", "<cmd>Telescope lsp_definitions<CR>", keymap_opts)
        vim.keymap.set("n", "gi", "<cmd>Telescope lsp_implementations<CR>", keymap_opts)
        vim.keymap.set("n", "gt", "<cmd>Telescope lsp_type_definitions<CR>", keymap_opts)
        vim.keymap.set({ "n", "v" }, "<leader>ca", vim.lsp.buf.code_action, keymap_opts)
        vim.keymap.set("n", "<leader>rn", vim.lsp.buf.rename, keymap_opts)
        vim.keymap.set("n", "<leader>D", "<cmd>Telescope diagnostics bufnr=0<CR>", keymap_opts)
        vim.keymap.set("n", "<leader>d", vim.diagnostic.open_float, keymap_opts)
        vim.keymap.set("n", "[d", vim.diagnostic.goto_prev, keymap_opts)
        vim.keymap.set("n", "]d", vim.diagnostic.goto_next, keymap_opts)
        vim.keymap.set("n", "K", vim.lsp.buf.hover, keymap_opts)
        vim.keymap.set("n", "<leader>rs", ":LspRestart<CR>", keymap_opts)
      end

      -- Prisma LSP setup
      vim.api.nvim_create_autocmd("FileType", {
        pattern = "prisma",
        callback = function()
          vim.lsp.start({
            name = "prismals",
            cmd = { "prisma-language-server", "--stdio" },
            root_dir = vim.fs.root(0, { "package.json", ".git" }),
            capabilities = capabilities,
            on_attach = on_attach,
          })
        end,
      })
    end,
  },

  -- Treesitter for Prisma syntax highlighting
  {
    "nvim-treesitter/nvim-treesitter",
    opts = function(_, opts)
      if type(opts.ensure_installed) == "table" then
        vim.list_extend(opts.ensure_installed, { "prisma" })
      end
    end,
  },

  -- Formatting for Prisma
  {
    "stevearc/conform.nvim",
    opts = function(_, opts)
      opts.formatters_by_ft = opts.formatters_by_ft or {}
      opts.formatters_by_ft.prisma = { "prisma" }
      opts.formatters = opts.formatters or {}
      opts.formatters.prisma = {
        command = "prisma",
        args = { "format", "--schema", "$FILENAME" },
        stdin = false,
      }
    end,
  },
}
