return {
  "nvimtools/none-ls.nvim",
  opts = function(_, opts)
    local null_ls = require("null-ls")
    
    -- Add additional sources that aren't covered by conform.nvim or nvim-lint
    opts.sources = vim.list_extend(opts.sources or {}, {
      -- Additional formatters not in conform.nvim
      null_ls.builtins.formatting.stylua, -- Lua formatting (if not using conform for this)
      
      -- Additional diagnostics not in nvim-lint
      -- Note: flake8 builtin has been removed, use nvim-lint or conform.nvim instead
      -- null_ls.builtins.diagnostics.flake8, -- Python diagnostics
      
      -- Code actions and other tools
      null_ls.builtins.code_actions.refactoring,
      null_ls.builtins.hover.dictionary,
    })
    
    return opts
  end,
}
