local ls = require("luasnip")
local s = ls.snippet
local t = ls.text_node

ls.add_snippets("typescript", {
    s("cl", {
        t("console.log('text');"),
    }),
    s("if", {
        t("if (${1:condition}) {\n\t$0\n}"),
    }),
    s("fun", {
        t("function ${1:name}(${2:args}) {\n\t$0\n}"),
    }),
    s("import", {
        t("import { ${2:obj} } from '${1:package}';"),
    }),
    s("interface", {
        t("interface ${1:InterfaceName} {\n\t${2:property}: ${3:type};\n}"),
    }),
})
