return {
  {
    "folke/which-key.nvim",
    opts = function(_, opts)
      -- The default LazyVim UI for which-key is snacks, which is disabled.
      -- We need to restore a different UI backend. `mini.pick` is a good alternative.
      opts.ui = {
        border = "rounded",
        title = true,
        win = "border",
        footer = true,
        padding = { 2, 2, 2, 2 },
        backend = "mini", -- Use mini.pick instead of snacks
      }
    end,
  },
}
