return {
  -- Diff previewer window shows the difference between the current node and the node under the cursor
  {
    "mbbill/undotree",
    lazy = false,
    keys = {
      vim.keymap.set("n", "<F5>", vim.cmd.UndotreeToggle),
    },
  },
}
