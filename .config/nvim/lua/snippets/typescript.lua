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

    -- React
    s(
        { trig = "component", dscr = "React functional component" },
        fmt(
            [[
      const {} = ({}) => {{
      {}return (
      {}        <div>
      {}          {}
      {}        </div>
      {});
      }};
      ]],
            {
                i(1, "ComponentName"),
                i(2, "props"),
                t("\t"),
                t("\t\t"),
                t("\t\t\t"),
                i(0),
                t("\t\t"),
                t("\t"),
            }
        )
    ),
    s(
        { trig = "useState", dscr = "React useState hook" },
        fmt(
            [[
      const [{}, set{}] = useState({});
      ]],
            {
                i(1, "state"),
                i(1, "", { user_data = { capitalize = true } }),
                i(2, "initialValue"),
            }
        )
    ),
    s(
        { trig = "useEffect", dscr = "React useEffect hook" },
        fmt(
            [[
      useEffect(() => {{
      {}{}
      {}return () => {{
      {}{}
      {}}};
      }}, [{}]);
      ]],
            {
                t("\t"),
                i(1, "effect"),
                t("\t"),
                t("\t\t"),
                i(2, "cleanup"),
                t("\t"),
                i(3, "dependencies"),
            }
        )
    ),
    s(
        { trig = "props", dscr = "React props interface" },
        fmt(
            [[
      interface {} {{
      {}{}: {};
      }}
      ]],
            {
                i(1, "PropsName"),
                t("\t"),
                i(2, "prop"),
                i(3, "type"),
            }
        )
    ),
})
