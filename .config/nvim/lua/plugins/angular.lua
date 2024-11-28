local map = vim.keymap.set

return {
  -- Angular component switcher
  {
    "softoika/ngswitcher.vim",
    init = function()
      map("n", "<leader>at", ":NgSwitchHTML<cr>", { desc = "Goto Template" })
      map("n", "<leader>ac", ":NgSwitchTS<cr>", { desc = "Goto Component" })
      map("n", "<leader>as", ":NgSwitchCSS<cr>", { desc = "Goto CSS" })
      map("n", "<leader>ae", ":NgSwitchSpec<cr>", { desc = "Goto Test" })
    end,
  },
}
