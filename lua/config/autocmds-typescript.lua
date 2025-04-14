-- ~/.config/nvim/lua/config/autocmds-typescript.lua
local augroup = vim.api.nvim_create_augroup("TypeScriptConfig", { clear = true })

-- Auto-format TypeScript/JavaScript files on save
vim.api.nvim_create_autocmd("BufWritePre", {
  pattern = { "*.ts", "*.tsx", "*.js", "*.jsx" },
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

-- Set indentation for TypeScript/JavaScript files
vim.api.nvim_create_autocmd("FileType", {
  pattern = { "typescript", "javascript", "typescriptreact", "javascriptreact" },
  callback = function()
    vim.opt_local.expandtab = true
    vim.opt_local.shiftwidth = 2
    vim.opt_local.tabstop = 2
    vim.opt_local.softtabstop = 2
  end,
  group = augroup,
})

-- Automatically install npm packages for new projects
vim.api.nvim_create_autocmd("BufEnter", {
  pattern = { "package.json" },
  callback = function()
    -- Check if node_modules exists
    local node_modules = vim.fn.getcwd() .. "/node_modules"
    if vim.fn.isdirectory(node_modules) == 0 then
      vim.notify("Node modules not found. Run ':terminal npm install' to install dependencies.", vim.log.levels.INFO)
    end
  end,
  group = augroup,
})

-- Set up template detection for Next.js and Nest.js files
vim.api.nvim_create_autocmd("BufNewFile", {
  pattern = { "pages/*.tsx", "pages/api/*.ts", "components/*.tsx" },
  callback = function()
    -- This is a Next.js file, load appropriate template
    local filename = vim.fn.expand("%:t")
    local filetype = vim.fn.expand("%:e")
    local template = ""

    if filetype == "tsx" then
      -- React component template
      template = [[import React from 'react'

interface Props {
  // Define your props here
}

export default function ]] .. filename:gsub("%.tsx$", "") .. [[({ }: Props) {
  return (
    <div>
      {/* Your component content */}
    </div>
  )
}
]]
    elseif filetype == "ts" and vim.fn.expand("%:p"):match("pages/api") then
      -- Next.js API route
      template = [[import type { NextApiRequest, NextApiResponse } from 'next'

type ResponseData = {
  message: string
}

export default function handler(
  req: NextApiRequest,
  res: NextApiResponse<ResponseData>
) {
  res.status(200).json({ message: 'Hello from API' })
}
]]
    end

    if template ~= "" then
      vim.api.nvim_buf_set_lines(0, 0, 0, false, vim.split(template, "\n"))
    end
  end,
  group = augroup,
})

-- Similar for Nest.js files
vim.api.nvim_create_autocmd("BufNewFile", {
  pattern = { "src/*.controller.ts", "src/*.service.ts", "src/*.module.ts" },
  callback = function()
    local filepath = vim.fn.expand("%:p")
    local template = ""

    if filepath:match("%.controller%.ts$") then
      -- Controller template
      local name = vim.fn.expand("%:t"):gsub("%.controller%.ts$", "")
      local className = name:gsub("^%l", string.upper) .. "Controller"

      template = [[import { Controller, Get } from '@nestjs/common';

@Controller(']] .. name .. [[')
export class ]] .. className .. [[ {
  @Get()
  findAll() {
    return { message: 'This action returns all ]] .. name .. [[' };
  }
}
]]
    elseif filepath:match("%.service%.ts$") then
      -- Service template
      local name = vim.fn.expand("%:t"):gsub("%.service%.ts$", "")
      local className = name:gsub("^%l", string.upper) .. "Service"

      template = [[import { Injectable } from '@nestjs/common';

@Injectable()
export class ]] .. className .. [[ {
  // Add your service methods here
}
]]
    elseif filepath:match("%.module%.ts$") then
      -- Module template
      local name = vim.fn.expand("%:t"):gsub("%.module%.ts$", "")
      local className = name:gsub("^%l", string.upper) .. "Module"

      template = [[import { Module } from '@nestjs/common';

@Module({
  imports: [],
  controllers: [],
  providers: [],
  exports: [],
})
export class ]] .. className .. [[ {}
]]
    end

    if template ~= "" then
      vim.api.nvim_buf_set_lines(0, 0, 0, false, vim.split(template, "\n"))
    end
  end,
  group = augroup,
})

-- For workspace management
vim.api.nvim_create_autocmd("BufRead", {
  pattern = { "tsconfig.json", "package.json" },
  callback = function()
    -- Set root directory to current directory for LSP
    vim.g.project_root = vim.fn.getcwd()
  end,
  group = augroup,
})
