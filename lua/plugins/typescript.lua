-- TypeScript/JavaScript configuration
return {
  -- Add TypeScript LSP to nvim-lspconfig
  {
    "neovim/nvim-lspconfig",
    opts = function(_, opts)
      local capabilities = require("cmp_nvim_lsp").default_capabilities()

      -- Get the on_attach function from the main lsp config
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

        -- Enable inlay hints if supported
        if client.server_capabilities.inlayHintProvider then
          vim.lsp.inlay_hint.enable(true, { bufnr = bufnr })
        end
      end

      -- TypeScript-specific on_attach with extra keymaps
      local ts_on_attach = function(client, bufnr)
        on_attach(client, bufnr)
        local keymap_opts = { buffer = bufnr, silent = true }

        -- TypeScript specific keymaps
        vim.keymap.set("n", "<leader>co", function()
          vim.lsp.buf.code_action({
            apply = true,
            context = { only = { "source.organizeImports" }, diagnostics = {} },
          })
        end, vim.tbl_extend("force", keymap_opts, { desc = "Organize imports" }))

        vim.keymap.set("n", "<leader>cM", function()
          vim.lsp.buf.code_action({
            apply = true,
            context = { only = { "source.addMissingImports.ts" }, diagnostics = {} },
          })
        end, vim.tbl_extend("force", keymap_opts, { desc = "Add missing imports" }))

        vim.keymap.set("n", "<leader>cu", function()
          vim.lsp.buf.code_action({
            apply = true,
            context = { only = { "source.removeUnused.ts" }, diagnostics = {} },
          })
        end, vim.tbl_extend("force", keymap_opts, { desc = "Remove unused imports" }))

        vim.keymap.set("n", "<leader>ci", function()
          vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled({ bufnr = bufnr }), { bufnr = bufnr })
        end, vim.tbl_extend("force", keymap_opts, { desc = "Toggle inlay hints" }))
      end

      -- TypeScript LSP (new v3.0.0 API)
      vim.lsp.config.ts_ls = {
        cmd = { "typescript-language-server", "--stdio" },
        filetypes = { "javascript", "javascriptreact", "javascript.jsx", "typescript", "typescriptreact", "typescript.tsx" },
        root_markers = { "tsconfig.json", "jsconfig.json", "package.json", ".git" },
        capabilities = capabilities,
        on_attach = ts_on_attach,
        settings = {
          typescript = {
            inlayHints = {
              includeInlayParameterNameHints = "all",
              includeInlayParameterNameHintsWhenArgumentMatchesName = false,
              includeInlayFunctionParameterTypeHints = true,
              includeInlayVariableTypeHints = true,
              includeInlayPropertyDeclarationTypeHints = true,
              includeInlayFunctionLikeReturnTypeHints = true,
              includeInlayEnumMemberValueHints = true,
            },
          },
          javascript = {
            inlayHints = {
              includeInlayParameterNameHints = "all",
              includeInlayParameterNameHintsWhenArgumentMatchesName = false,
              includeInlayFunctionParameterTypeHints = true,
              includeInlayVariableTypeHints = true,
              includeInlayPropertyDeclarationTypeHints = true,
              includeInlayFunctionLikeReturnTypeHints = true,
              includeInlayEnumMemberValueHints = true,
            },
          },
        },
      }

      -- ESLint LSP (new v3.0.0 API)
      vim.lsp.config.eslint = {
        cmd = { "vscode-eslint-language-server", "--stdio" },
        filetypes = { "javascript", "javascriptreact", "javascript.jsx", "typescript", "typescriptreact", "typescript.tsx", "vue", "svelte", "astro" },
        root_markers = { ".eslintrc", ".eslintrc.js", ".eslintrc.cjs", ".eslintrc.yaml", ".eslintrc.yml", ".eslintrc.json", "eslint.config.js", "eslint.config.mjs", "eslint.config.cjs" },
        capabilities = capabilities,
        on_attach = function(client, bufnr)
          on_attach(client, bufnr)
          -- Auto-fix on save
          vim.api.nvim_create_autocmd("BufWritePre", {
            buffer = bufnr,
            command = "EslintFixAll",
          })
        end,
      }

      -- Enable TypeScript LSP servers
      vim.lsp.enable({ "ts_ls", "eslint" })
    end,
  },

  -- Formatting with conform.nvim
  {
    "stevearc/conform.nvim",
    event = { "BufReadPre", "BufNewFile" },
    config = function()
      require("conform").setup({
        formatters_by_ft = {
          javascript = { "prettier" },
          javascriptreact = { "prettier" },
          typescript = { "prettier" },
          typescriptreact = { "prettier" },
          json = { "prettier" },
          html = { "prettier" },
          css = { "prettier" },
          markdown = { "prettier" },
        },
        format_on_save = {
          timeout_ms = 500,
          lsp_fallback = true,
        },
      })

      -- Keymap for manual formatting
      vim.keymap.set({ "n", "v" }, "<leader>mp", function()
        require("conform").format({
          lsp_fallback = true,
          async = false,
          timeout_ms = 500,
        })
      end, { desc = "Format file or range (in visual mode)" })
    end,
  },

  -- Add keymaps for running TypeScript files
  {
    "folke/which-key.nvim",
    optional = true,
    opts = {
      defaults = {
        ["<leader>r"] = { name = "+run" },
      },
    },
  },
}
