-- Mini.ai - Better text objects
return {
  "echasnovski/mini.ai",
  event = "VeryLazy",
  dependencies = {
    "nvim-treesitter/nvim-treesitter-textobjects",
  },
  opts = function()
    local ai = require("mini.ai")
    return {
      n_lines = 500,
      custom_textobjects = {
        -- Code block
        o = ai.gen_spec.treesitter({
          a = { "@block.outer", "@conditional.outer", "@loop.outer" },
          i = { "@block.inner", "@conditional.inner", "@loop.inner" },
        }),
        -- Function
        f = ai.gen_spec.treesitter({ a = "@function.outer", i = "@function.inner" }),
        -- Class
        c = ai.gen_spec.treesitter({ a = "@class.outer", i = "@class.inner" }),
        -- Argument/parameter
        a = ai.gen_spec.treesitter({ a = "@parameter.outer", i = "@parameter.inner" }),
      },
    }
  end,
}
