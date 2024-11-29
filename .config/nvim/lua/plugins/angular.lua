local map = vim.keymap.set

return {
  -- Angular component switcher
  {
    "Everduin94/nvim-quick-switcher",
    init = function()
      map(
        "n",
        "<leader>ac",
        "<cmd>:lua require('nvim-quick-switcher').find('.component.ts')<CR>",
        { noremap = true, silent = true, desc = "Goto Class" }
      )
      map(
        "n",
        "<leader>at",
        "<cmd>:lua require('nvim-quick-switcher').find('.component.html')<CR>",
        { noremap = true, silent = true, desc = "Goto Template" }
      )
      map(
        "n",
        "<leader>as",
        "<cmd>:lua require('nvim-quick-switcher').find('.+css|.+scss|.+sass|.+less|.+style', { regex = true, prefix='full' })<CR>",
        { noremap = true, silent = true, desc = "Goto Style" }
      )
      map(
        "n",
        "<leader>ae",
        "<cmd>:lua require('nvim-quick-switcher').find('.+spec|.+test|.+e2e-spec.ts', { regex = true, prefix='full' })<CR>",
        { noremap = true, silent = true, desc = "Goto tEst" }
      )
      map(
        "n",
        "<leader>am",
        "<cmd>:lua require('nvim-quick-switcher').find('.module.ts')<CR>",
        { noremap = true, silent = true, desc = "Goto Module" }
      )
      map(
        "n",
        "<leader>au",
        "<cmd>:lua require('nvim-quick-switcher').find('*-routing.module.ts')<CR>",
        { noremap = true, silent = true, desc = "Goto roUting module" }
      )
      map(
        "n",
        "<leader>ao",
        "<cmd>:lua require('nvim-quick-switcher').find('.+model.ts|.+models.ts|.+types.ts', { regex = true })<CR>",
        { noremap = true, silent = true, desc = "Goto mOdel" }
      )
      map(
        "n",
        "<leader>ar",
        "<cmd>:lua require('nvim-quick-switcher').find('.service.ts')<CR>",
        { noremap = true, silent = true, desc = "Goto seRvice" }
      )
    end,
  },
}
