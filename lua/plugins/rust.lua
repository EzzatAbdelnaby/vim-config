-- Rust configuration
return {
  {
    "neovim/nvim-lspconfig",
    ft = "rust",
    config = function()
      local ok, cmp_nvim_lsp = pcall(require, "cmp_nvim_lsp")
      local capabilities = ok and cmp_nvim_lsp.default_capabilities() or vim.lsp.protocol.make_client_capabilities()

      vim.lsp.config.rust_analyzer = {
        cmd = { "rust-analyzer" },
        filetypes = { "rust" },
        root_markers = { "Cargo.toml", "rust-project.json" },
        capabilities = capabilities,
        on_attach = function(client, bufnr)
          local opts = { buffer = bufnr, silent = true }

          vim.keymap.set("n", "gR", "<cmd>Telescope lsp_references<CR>", opts)
          vim.keymap.set("n", "gD", vim.lsp.buf.declaration, opts)
          vim.keymap.set("n", "gd", "<cmd>Telescope lsp_definitions<CR>", opts)
          vim.keymap.set("n", "gi", "<cmd>Telescope lsp_implementations<CR>", opts)
          vim.keymap.set("n", "gt", "<cmd>Telescope lsp_type_definitions<CR>", opts)
          vim.keymap.set({ "n", "v" }, "<leader>ca", vim.lsp.buf.code_action, opts)
          vim.keymap.set("n", "<leader>rn", vim.lsp.buf.rename, opts)
          vim.keymap.set("n", "<leader>D", "<cmd>Telescope diagnostics bufnr=0<CR>", opts)
          vim.keymap.set("n", "<leader>d", vim.diagnostic.open_float, opts)
          vim.keymap.set("n", "[d", vim.diagnostic.goto_prev, opts)
          vim.keymap.set("n", "]d", vim.diagnostic.goto_next, opts)
          vim.keymap.set("n", "K", vim.lsp.buf.hover, opts)
          vim.keymap.set("n", "<leader>rs", ":LspRestart<CR>", opts)

          if client.server_capabilities.inlayHintProvider then
            vim.lsp.inlay_hint.enable(false, { bufnr = bufnr })
          end
          vim.keymap.set("n", "<leader>ih", function()
            vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled({ bufnr = bufnr }), { bufnr = bufnr })
          end, vim.tbl_extend("force", opts, { desc = "Toggle inlay hints" }))

          vim.keymap.set("n", "<leader>rc", function()
            vim.cmd("!cargo check")
          end, vim.tbl_extend("force", opts, { desc = "Cargo check" }))

          vim.keymap.set("n", "<leader>rr", function()
            vim.cmd("!cargo run")
          end, vim.tbl_extend("force", opts, { desc = "Cargo run" }))

          vim.keymap.set("n", "<leader>rt", function()
            vim.cmd("!cargo test")
          end, vim.tbl_extend("force", opts, { desc = "Cargo test" }))
        end,
        settings = {
          ["rust-analyzer"] = {
            checkOnSave = {
              command = "clippy",
            },
            cargo = {
              allFeatures = true,
            },
            procMacro = {
              enable = true,
            },
            completion = {
              fullFunctionSignatures = { enable = true },
            },
          },
        },
      }

      vim.lsp.enable("rust_analyzer")
    end,
  },

  -- Add rustfmt to conform
  {
    "stevearc/conform.nvim",
    opts = function(_, opts)
      opts.formatters_by_ft = opts.formatters_by_ft or {}
      opts.formatters_by_ft.rust = { "rustfmt" }
    end,
  },
}
