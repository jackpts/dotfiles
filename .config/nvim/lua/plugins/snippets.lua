return {
  -- https://github.com/rafamadriz/friendly-snippets/wiki
  "rafamadriz/friendly-snippets",

  {
    "L3MON4D3/LuaSnip",
    -- requires = { "rafamadriz/friendly-snippets" },
    config = function()
      require("luasnip.loaders.from_lua").load({ paths = { "~/.config/nvim/lua/snippets/" } })
    end,
  },
}
