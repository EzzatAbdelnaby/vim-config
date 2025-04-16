-- ~/.config/nvim/lua/plugins/docker.lua
return {
  -- Mason for Docker-related tools
  {
    "williamboman/mason.nvim",
    opts = function(_, opts)
      opts.ensure_installed = opts.ensure_installed or {}
      vim.list_extend(opts.ensure_installed, {
        "dockerfile-language-server", -- Dockerfile LSP
        "docker-compose-language-service", -- Docker Compose support
      })
    end,
  },

  -- LSP Configuration for Docker
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        -- Dockerfile language server
        dockerls = {
          settings = {
            docker = {
              languageserver = {
                diagnostics = {
                  enable = true,
                  deprecatedMaintainer = true,
                  directiveCasing = true,
                  emptyContinuationLine = true,
                },
                formatter = {
                  enable = true,
                },
              },
            },
          },
        },
        -- Docker Compose language server
        docker_compose_language_service = {},
      },
    },
  },

  -- Add Treesitter parsers for Docker
  {
    "nvim-treesitter/nvim-treesitter",
    opts = function(_, opts)
      if type(opts.ensure_installed) == "table" then
        vim.list_extend(opts.ensure_installed, {
          "dockerfile",
        })
      end
    end,
  },

  -- Specify Docker compose filetype for YAML files
  {
    "LazyVim/LazyVim",
    opts = function()
      vim.api.nvim_create_autocmd({ "BufNewFile", "BufRead" }, {
        pattern = {
          "docker-compose*.yml",
          "docker-compose*.yaml",
          "**/docker-compose/**/*.yml",
          "**/docker-compose/**/*.yaml",
        },
        callback = function()
          vim.bo.filetype = "yaml.docker-compose"
        end,
      })
    end,
  },

  -- Add keymaps for Docker commands
  {
    "nvim-telescope/telescope.nvim",
    keys = {
      {
        "<leader>D",
        name = "+docker",
      },
      {
        "<leader>Db",
        function()
          vim.cmd("terminal docker build -t " .. vim.fn.fnamemodify(vim.fn.getcwd(), ":t") .. " .")
        end,
        desc = "Docker Build",
      },
      {
        "<leader>Dr",
        function()
          vim.cmd("terminal docker run -it " .. vim.fn.fnamemodify(vim.fn.getcwd(), ":t"))
        end,
        desc = "Docker Run",
      },
      {
        "<leader>Dc",
        function()
          vim.cmd("terminal docker-compose up")
        end,
        desc = "Docker Compose Up",
      },
      {
        "<leader>Cd",
        function()
          vim.cmd("terminal docker-compose down")
        end,
        desc = "Docker Compose Down",
      },
      {
        "<leader>Di",
        function()
          vim.cmd("terminal docker images")
        end,
        desc = "Docker Images",
      },
      {
        "<leader>Dp",
        function()
          vim.cmd("terminal docker ps")
        end,
        desc = "Docker PS",
      },
    },
  },

  -- Docker file templates
  {
    "LazyVim/LazyVim",
    opts = function()
      vim.api.nvim_create_autocmd("BufNewFile", {
        pattern = "Dockerfile",
        callback = function()
          -- Detect if this might be a Node.js or TypeScript project
          local is_node = vim.fn.filereadable("package.json") == 1

          local template = ""

          if is_node then
            -- Template for Node.js/TypeScript applications
            template = [[
# Stage 1: Building the code
FROM node:18-alpine as builder

WORKDIR /app

# Copy package.json and package-lock.json
COPY package*.json ./

# Install dependencies
RUN npm ci

# Copy the rest of the code
COPY . .

# Build the application
RUN npm run build

# Stage 2: Running the application
FROM node:18-alpine as runner

WORKDIR /app

# Copy built assets from the builder stage
COPY --from=builder /app/node_modules ./node_modules
COPY --from=builder /app/package*.json ./
COPY --from=builder /app/dist ./dist

# Set NODE_ENV
ENV NODE_ENV=production

# Expose the port
EXPOSE 3000

# Start the application
CMD ["npm", "start"]
]]
          else
            -- Generic Dockerfile template
            template = [[
FROM alpine:latest

WORKDIR /app

COPY . .

CMD ["sh", "-c", "echo 'Container is running...'"]
]]
          end

          vim.api.nvim_buf_set_lines(0, 0, 0, false, vim.split(template, "\n"))
        end,
      })

      -- Docker Compose template
      vim.api.nvim_create_autocmd("BufNewFile", {
        pattern = "docker-compose.yml",
        callback = function()
          local template = [[
version: '3.8'

services:
  app:
    build:
      context: .
      dockerfile: Dockerfile
    ports:
      - "3000:3000"
    volumes:
      - .:/app
      - /app/node_modules
    environment:
      - NODE_ENV=development
    depends_on:
      - db
    
  db:
    image: postgres:13
    environment:
      POSTGRES_USER: postgres
      POSTGRES_PASSWORD: postgres
      POSTGRES_DB: app_db
    ports:
      - "5432:5432"
    volumes:
      - postgres_data:/var/lib/postgresql/data

volumes:
  postgres_data:
]]

          vim.api.nvim_buf_set_lines(0, 0, 0, false, vim.split(template, "\n"))
        end,
      })
    end,
  },

  -- Setup which-key mappings for Docker commands
  {
    "folke/which-key.nvim",
    optional = true,
    opts = {
      defaults = {
        -- Use the new format for Docker group
        { "<leader>D", { name = "+docker", _ = "which_key_ignore" } },
        { "<leader>Di", { "<cmd>terminal docker images<cr>", "Docker Images" } },
        { "<leader>Dc", { "<cmd>terminal docker-compose up -d<cr>", "Docker Compose Up" } },
        { "<leader>Db", { "<cmd>terminal docker build .<cr>", "Docker Build" } },
        { "<leader>Dr", { "<cmd>terminal docker run<cr>", "Docker Run" } },
        { "<leader>Dp", { "<cmd>terminal docker ps<cr>", "Docker PS" } },
      },
    },
  },
}
