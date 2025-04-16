-- ~/.config/nvim/lua/config/autocmds-react.lua
local augroup = vim.api.nvim_create_augroup("ReactConfig", { clear = true })

-- Auto-format React files on save
vim.api.nvim_create_autocmd("BufWritePre", {
  pattern = { "*.tsx", "*.jsx", "*.js", "*.ts", "*.css", "*.scss" },
  callback = function()
    -- Use conform.nvim if available
    if package.loaded["conform"] then
      require("conform").format({ bufnr = 0 })
    else
      -- Check if lsp formatting is available
      local status, _ = pcall(function()
        vim.lsp.buf.format({ async = false })
      end)

      -- If LSP formatting fails, silently continue
      if not status then
        vim.notify("LSP formatting not available yet. Install and set up a formatter.", vim.log.levels.DEBUG)
      end
    end
  end,
  group = augroup,
})

-- Set indentation for React files
vim.api.nvim_create_autocmd("FileType", {
  pattern = { "javascript", "javascriptreact", "typescript", "typescriptreact" },
  callback = function()
    vim.opt_local.expandtab = true
    vim.opt_local.shiftwidth = 2
    vim.opt_local.tabstop = 2
    vim.opt_local.softtabstop = 2
  end,
  group = augroup,
})

-- CSS/SCSS indentation
vim.api.nvim_create_autocmd("FileType", {
  pattern = { "css", "scss" },
  callback = function()
    vim.opt_local.expandtab = true
    vim.opt_local.shiftwidth = 2
    vim.opt_local.tabstop = 2
    vim.opt_local.softtabstop = 2
  end,
  group = augroup,
})

-- Automatically detect React projects
vim.api.nvim_create_autocmd("BufEnter", {
  pattern = { "package.json" },
  callback = function()
    -- Check if this is likely a React project
    local file = io.open(vim.fn.expand("%:p"), "r")
    if file then
      local content = file:read("*all")
      file:close()

      if content:match('"react"') then
        vim.notify("React project detected", vim.log.levels.INFO)

        -- Check if common React dependencies are installed
        local missing_deps = {}
        local deps = {
          "eslint",
          "prettier",
          "@testing-library/react",
          "typescript",
        }

        for _, dep in ipairs(deps) do
          if not content:match('"' .. dep .. '"') then
            table.insert(missing_deps, dep)
          end
        end

        if #missing_deps > 0 then
          vim.notify(
            "Consider installing these React dependencies: " .. table.concat(missing_deps, ", "),
            vim.log.levels.INFO
          )
        end
      end
    end
  end,
  group = augroup,
})

-- JSX/TSX comment string setup
vim.api.nvim_create_autocmd("FileType", {
  pattern = { "javascriptreact", "typescriptreact" },
  callback = function()
    vim.bo.commentstring = "{/* %s */}"
  end,
  group = augroup,
})

-- Add React path intelligence (for imports)
vim.api.nvim_create_autocmd({ "BufNewFile", "BufRead" }, {
  pattern = { "*.js", "*.jsx", "*.ts", "*.tsx" },
  callback = function()
    if vim.fn.filereadable("jsconfig.json") == 1 or vim.fn.filereadable("tsconfig.json") == 1 then
      -- The project has a jsconfig/tsconfig, so likely has path aliases
      if vim.fn.exists(":TSLspImportAll") == 2 then
        -- If there's a command to import all, create a key binding for it
        vim.keymap.set("n", "<leader>ri", "<cmd>TSLspImportAll<CR>", { buffer = true, desc = "Import All" })
      end

      if vim.fn.exists(":TSLspOrganizeImports") == 2 then
        vim.keymap.set("n", "<leader>ro", "<cmd>TSLspOrganizeImports<CR>", { buffer = true, desc = "Organize Imports" })
      end
    end
  end,
  group = augroup,
})

-- Create useful snippets for React hooks
vim.api.nvim_create_autocmd("FileType", {
  pattern = { "javascriptreact", "typescriptreact" },
  callback = function()
    -- Check if LuaSnip is available
    if package.loaded["luasnip"] then
      local ls = require("luasnip")
      local s = ls.snippet
      local t = ls.text_node
      local i = ls.insert_node

      ls.add_snippets("typescriptreact", {
        -- useState snippet
        s("ust", {
          t("const ["),
          i(1, "state"),
          t(", set"),
          i(2, "State"),
          t("] = useState"),
          t("<"),
          i(3, "type"),
          t(">("),
          i(4, "initialValue"),
          t(");"),
        }),

        -- useEffect snippet
        s("uef", {
          t("useEffect(() => {"),
          t({ "", "  " }),
          i(1, "// effect code"),
          t({ "", "  " }),
          t({ "", "  return () => {" }),
          t({ "", "    " }),
          i(2, "// cleanup code"),
          t({ "", "  }" }),
          t({ "", "}, [" }),
          i(3, "/* dependencies */"),
          t("]);"),
        }),

        -- useContext snippet
        s("uco", {
          t("const "),
          i(1, "contextValue"),
          t(" = useContext("),
          i(2, "MyContext"),
          t(");"),
        }),
      })

      -- Same snippets for JavaScript React
      ls.add_snippets("javascriptreact", {
        -- useState snippet
        s("ust", {
          t("const ["),
          i(1, "state"),
          t(", set"),
          i(2, "State"),
          t("] = useState("),
          i(3, "initialValue"),
          t(");"),
        }),

        -- useEffect snippet
        s("uef", {
          t("useEffect(() => {"),
          t({ "", "  " }),
          i(1, "// effect code"),
          t({ "", "  " }),
          t({ "", "  return () => {" }),
          t({ "", "    " }),
          i(2, "// cleanup code"),
          t({ "", "  }" }),
          t({ "", "}, [" }),
          i(3, "/* dependencies */"),
          t("]);"),
        }),

        -- useContext snippet
        s("uco", {
          t("const "),
          i(1, "contextValue"),
          t(" = useContext("),
          i(2, "MyContext"),
          t(");"),
        }),
      })
    end
  end,
  group = augroup,
})
