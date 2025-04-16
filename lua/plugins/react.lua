-- ~/.config/nvim/lua/plugins/react.lua
return {
  -- Mason for React-related tools
  {
    "williamboman/mason.nvim",
    opts = function(_, opts)
      opts.ensure_installed = opts.ensure_installed or {}
      vim.list_extend(opts.ensure_installed, {
        "css-lsp", -- CSS language server
        "eslint-lsp", -- ESLint language server
        "html-lsp", -- HTML language server
        "typescript-language-server", -- TypeScript/JavaScript language server
        "prettier", -- Code formatter
        "stylelint-lsp", -- CSS/SCSS/Less linter
        "tailwindcss-language-server", -- Tailwind CSS intellisense
        "emmet-ls", -- Emmet language server for HTML/CSS expansions
      })
    end,
  },

  -- LSP configurations for React development
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        -- TypeScript/JavaScript
        tsserver = {
          settings = {
            -- Enhanced settings for React development
            typescript = {
              suggestionActions = { enabled = true },
              preferences = {
                quoteStyle = "single", -- Use single quotes
                jsxAttributeCompletionStyle = "auto",
              },
              inlayHints = {
                includeInlayParameterNameHints = "all",
                includeInlayParameterNameHintsWhenArgumentMatchesName = false,
                includeInlayFunctionParameterTypeHints = true,
                includeInlayVariableTypeHints = true,
                includeInlayPropertyDeclarationTypeHints = true,
                includeInlayFunctionLikeReturnTypeHints = true,
              },
            },
            javascript = {
              suggestionActions = { enabled = true },
              preferences = {
                quoteStyle = "single", -- Use single quotes
                jsxAttributeCompletionStyle = "auto",
              },
            },
          },
        },

        -- Tailwind CSS
        tailwindcss = {
          init_options = {
            userLanguages = {
              elixir = "phoenix-heex",
              eruby = "erb",
              heex = "phoenix-heex",
              svelte = "html",
              javascriptreact = "javascript",
              typescriptreact = "typescript",
            },
          },
          settings = {
            tailwindCSS = {
              experimental = {
                classRegex = {
                  -- Support for clsx/cva
                  "cva\\(([^)]*)\\)",
                  "cx\\(([^)]*)\\)",
                  "clsx\\(([^)]*)\\)",
                  -- Support for styled components/emotion css prop
                  { "css\\s*`([^`]*)`", "[\"'`]([^\"'`]*)[\"'`]" },
                  { "className\\s*=\\s*[\"']([^\"']*)[\"']" },
                },
              },
              includeLanguages = {
                typescript = "javascript",
                typescriptreact = "javascript",
                ["html-eex"] = "html",
                ["phoenix-heex"] = "html",
                heex = "html",
                eelixir = "html",
                elm = "html",
                erb = "html",
                svelte = "html",
              },
            },
          },
          filetypes = {
            "css",
            "scss",
            "sass",
            "postcss",
            "html",
            "javascript",
            "javascriptreact",
            "typescript",
            "typescriptreact",
            "svelte",
            "vue",
            "heex",
            "elixir",
          },
        },

        -- Emmet for faster HTML/CSS writing
        emmet_ls = {
          filetypes = {
            "html",
            "typescriptreact",
            "javascriptreact",
            "javascript.jsx",
            "typescript.tsx",
            "css",
            "sass",
            "scss",
            "less",
          },
          init_options = {
            html = {
              options = {
                -- For possible options, see: https://github.com/emmetio/emmet/blob/master/src/config.ts#L79-L267
                ["bem.enabled"] = true,
                ["jsx.enabled"] = true,
              },
            },
          },
        },

        -- CSS
        cssls = {
          settings = {
            css = {
              validate = true,
              lint = {
                unknownAtRules = "ignore", -- Ignore unknown at-rules (tailwind)
              },
            },
            scss = {
              validate = true,
              lint = {
                unknownAtRules = "ignore",
              },
            },
            less = {
              validate = true,
              lint = {
                unknownAtRules = "ignore",
              },
            },
          },
        },
      },
    },
  },

  -- Improved TypeScript/JSX syntax highlighting
  {
    "nvim-treesitter/nvim-treesitter",
    opts = function(_, opts)
      if type(opts.ensure_installed) == "table" then
        vim.list_extend(opts.ensure_installed, {
          "typescript",
          "tsx",
          "javascript",
          "html",
          "css",
          "scss",
          "graphql",
          "json",
          "jsonc",
          "jsdoc",
        })
      end
    end,
  },

  -- Auto-completion improvements for React
  {
    "hrsh7th/nvim-cmp",
    dependencies = {
      -- Add emmet-vim snippets to cmp
      "dcampos/cmp-emmet-vim",
      "mattn/emmet-vim",

      -- JSX/TSX tag pair colorization
      "leafoftree/vim-jsx-improve",
    },
    opts = function(_, opts)
      -- Add emmet source
      table.insert(opts.sources, { name = "emmet_vim" })

      -- Improve auto-closing for JSX
      local cmp = require("cmp")
      opts.mapping = vim.tbl_extend("force", opts.mapping, {
        ["<C-Space>"] = cmp.mapping.complete(),
      })
    end,
  },

  -- Add formatting for React files
  {
    "stevearc/conform.nvim",
    optional = true,
    opts = {
      formatters_by_ft = {
        javascript = { "prettier" },
        javascriptreact = { "prettier" },
        typescript = { "prettier" },
        typescriptreact = { "prettier" },
        css = { "prettier" },
        scss = { "prettier" },
        html = { "prettier" },
        json = { "prettier" },
        graphql = { "prettier" },
      },
    },
  },

  -- React specific snippets
  {
    "L3MON4D3/LuaSnip",
    dependencies = { "rafamadriz/friendly-snippets" },
    opts = function(_, opts)
      -- Ensure friendly-snippets loads React snippets
      require("luasnip.loaders.from_vscode").lazy_load()

      -- Add custom React snippets
      opts.snippets = opts.snippets or {}

      -- Example of a custom React component snippet
      table.insert(opts.snippets, {
        filetype = { "javascriptreact", "typescriptreact" },
        snippets = {
          react_component = {
            description = "React functional component",
            trig = "rfc",
            body = [[
import React from 'react';

interface Props {
  ${1:// props}
}

export const ${2:ComponentName}: React.FC<Props> = ({${3}}) => {
  return (
    <div>
      ${4}
    </div>
  );
};
            ]],
          },
        },
      })
    end,
  },

  -- React file templates
  {
    "LazyVim/LazyVim",
    opts = function()
      vim.api.nvim_create_autocmd("BufNewFile", {
        pattern = { "*.tsx", "*.jsx" },
        callback = function()
          -- Determine what type of file we're creating
          local filename = vim.fn.expand("%:t")
          local filetype = vim.fn.expand("%:e")
          local template = ""

          if filetype == "tsx" then
            -- React TypeScript component template
            template = [[import React from 'react';

interface Props {
  // Define your props here
}

export const ]] .. filename:gsub("%.tsx$", "") .. [[: React.FC<Props> = (props) => {
  return (
    <div>
      {/* Your component content */}
    </div>
  );
};

export default ]] .. filename:gsub("%.tsx$", "") .. [[;
]]
          elseif filetype == "jsx" then
            -- React JavaScript component template
            template = [[import React from 'react';

export const ]] .. filename:gsub("%.jsx$", "") .. [[ = (props) => {
  return (
    <div>
      {/* Your component content */}
    </div>
  );
};

export default ]] .. filename:gsub("%.jsx$", "") .. [[;
]]
          end

          if template ~= "" then
            vim.api.nvim_buf_set_lines(0, 0, 0, false, vim.split(template, "\n"))
          end
        end,
      })
    end,
  },

  -- Keymaps for running and testing React apps
  {
    "nvim-telescope/telescope.nvim",
    keys = {
      {
        "<leader>rr",
        function()
          vim.cmd("terminal npm run start")
        end,
        desc = "Run React dev server",
      },
      {
        "<leader>rb",
        function()
          vim.cmd("terminal npm run build")
        end,
        desc = "Build React app",
      },
      {
        "<leader>rt",
        function()
          vim.cmd("terminal npm test")
        end,
        desc = "Run React tests",
      },
      {
        "<leader>rc",
        function()
          local filename = vim.fn.expand("%:t")
          local basename = filename:gsub("%.tsx$", ""):gsub("%.jsx$", "")
          local is_tsx = filename:match("%.tsx$")

          -- Create a test file
          local testfile = vim.fn.expand("%:p:h") .. "/" .. basename .. ".test." .. (is_tsx and "tsx" or "jsx")
          vim.cmd("edit " .. testfile)

          if vim.fn.filereadable(testfile) == 0 then
            local template = [[import React from 'react';
import { render, screen } from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import ]] .. basename .. [[ from './]] .. basename .. [[';

describe(']] .. basename .. [[', () => {
  test('renders correctly', () => {
    render(<]] .. basename .. [[ />);
    // Add your test assertions here
  });
});
]]
            vim.api.nvim_buf_set_lines(0, 0, 0, false, vim.split(template, "\n"))
          end
        end,
        desc = "Create/Open React test file",
      },
    },
  },
}
