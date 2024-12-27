-- Dad Bod Plugins, found by video: https://www.youtube.com/watch?v=ALGBuFLzDSA
-- Commands:
-- :DBUI, :tabnew, :DB mysql://jacky@localhost/
--  <Leader>D = toggle DBUI, <Leader>S = run query, <Leader>W = save query
return {
  { "tpope/vim-dadbod", lazy = true },
  { "kristijanhusak/vim-dadbod-completion", ft = { "sql", "mysql", "plsql" }, lazy = true },
  {
    "kristijanhusak/vim-dadbod-ui",
    event = "VeryLazy",
    cmd = {
      "DBUI",
      "DBUIToggle",
      "DBUIAddConnection",
      "DBUIFindBuffer",
    },
    init = function()
      vim.g.db_ui_use_nerd_fonts = 1
    end,
  },
}
