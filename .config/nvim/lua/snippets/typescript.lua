local ls = require("luasnip")
local s = ls.snippet
local t = ls.text_node
local i = ls.insert_node
local fmt = require("luasnip.extras.fmt").fmt

ls.add_snippets("typescript", {
    s("cl", {
        t("console.log('text');"),
    }),
    s(
        { trig = "fun", dscr = "Function declaration" },
        fmt(
            [[
      function {}({}) {{
      {}    {}
      }}
      ]],
            {
                i(1, "name"),
                i(2, "args"),
                t("\t"),
                i(0),
            }
        )
    ),
    s(
        { trig = "import", dscr = "Import statement" },
        fmt(
            [[
      import {{ {} }} from "{}";
      ]],
            {
                i(2, "obj"),
                i(1, "package"),
            }
        )
    ),
    s(
        { trig = "interface", dscr = "Interface declaration" },
        fmt(
            [[
      interface {} {{
      {}{}: {};
      }}
      ]],
            {
                i(1, "InterfaceName"),
                t("\t"),
                i(2, "property"),
                i(3, "type"),
            }
        )
    ),
})
