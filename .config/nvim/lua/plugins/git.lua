local map = vim.keymap.set

return {
  -- Diff Git View open in New Buffer
  -- Get started by opening file history for:
  -- >> The current branch: :DiffviewFileHistory
  -- >> The current file: :DiffviewFileHistory %
  -- Calling :DiffviewOpen with no args opens a new Diffview that compares against the current index
  -- You can also provide any valid git rev to view: :DiffviewOpen HEAD~2
  { "sindrets/diffview.nvim" },

  -- Git signs
  {
    "lewis6991/gitsigns.nvim",
    config = function()
      require("gitsigns").setup()

      map("n", "<leader>gp", ":Gitsigns preview_hunk<CR>", {})
      map("n", "<leader>gt", ":Gitsigns toggle_current_line_blame<CR>", {})
    end,
  },

  -- Interface for Neovim, inspired by Magit
  -- :Neogit             " Open the status buffer in a new tab
  -- :Neogit cwd=<cwd>   " Use a different repository path
  -- :Neogit cwd=%:p:h   " Uses the repository of the current file
  -- :Neogit kind=<kind> " Open specified popup directly
  -- :Neogit commit      " Open commit popup
  {
    "NeogitOrg/neogit",
    dependencies = {
      "nvim-lua/plenary.nvim", -- required
      "sindrets/diffview.nvim", -- optional - Diff integration

      -- Only one of these is needed.
      "nvim-telescope/telescope.nvim", -- optional
      "ibhagwan/fzf-lua", -- optional
      "echasnovski/mini.pick", -- optional
    },
    config = true,
  },
}
