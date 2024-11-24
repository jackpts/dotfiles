local map = vim.keymap.set

return {
  -- Angular language server extra functionality for Neovim LSP
  {
    "joeveiga/ng.nvim",
    init = function()
      local opts = { noremap = true, silent = true }
      local ng = require("ng")
      map(
        "n",
        "<leader>at",
        ng.goto_template_for_component,
        vim.tbl_extend("force", opts, { desc = "Goto template for component" })
      )
      -- vim.keymap.set("n", "<leader>at", ng.goto_template_for_component, { reuse_window = true } )
      map(
        "n",
        "<leader>ac",
        ng.goto_component_with_template_file,
        vim.tbl_extend("force", opts, { desc = "Goto component w/ template file" })
      )
      map("n", "<leader>aT", ng.get_template_tcb, vim.tbl_extend("force", opts, { desc = "Get template" }))
    end,
  },

  { "nvim-treesitter/nvim-treesitter-angular" },
}
