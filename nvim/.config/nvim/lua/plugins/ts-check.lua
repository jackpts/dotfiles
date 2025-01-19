-- To run TypeScript type-checking, execute the :TSC command in Neovim.
-- To stop any running :TSC command, use the :TSCStop command in Neovim
return {
  "dmmulroy/tsc.nvim",
  init = function()
    require("tsc").setup({
      run_as_monorepo = true,
      -- vim.keymap.set('n', '<leader>to', ':TSCOpen<CR>')
      -- vim.keymap.set('n', '<leader>tc', ':TSCClose<CR>')
    })
  end,
}
