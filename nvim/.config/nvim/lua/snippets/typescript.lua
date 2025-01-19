local ls = require("luasnip")
local s = ls.snippet
local t = ls.text_node

ls.add_snippets("typescript", {
  s("cl", {
    t("console.log('text');"),
  }),
})
