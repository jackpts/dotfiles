return {
  "lambdalisue/vim-suda",
  config = function()
    vim.g.suda_smart_edit = 1
    -- Expand 'ss' into 'SudaWrite' in the command line
    vim.cmd([[cab ss SudaWrite]])
  end,
}
