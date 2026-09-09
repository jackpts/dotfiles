return {
  {
    "2kabhishek/nerdy.nvim",
    dependencies = {
      "nvim-telescope/telescope.nvim",
      'folke/snacks.nvim',
    },
    cmd = {
      "Nerdy",
    },
    config = function()
      require('nerdy').setup({})
      -- Load telescope extension if telescope is available
      local ok, telescope = pcall(require, 'telescope')
      if ok then
        telescope.load_extension('nerdy')
      end
    end,
  },
}
