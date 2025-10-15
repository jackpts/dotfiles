return {
    "mfussenegger/nvim-lint",
    opts = {
        linters_by_ft = {
            c = { "cpplint" },
            cpp = { "cpplint" },
            sh = { "shellcheck" },
            bash = { "shellcheck" },
            rust = { "clippy" },
            python = { "pylint" },
            lua = { "luacheck" },
            sql = { "sqlfluff" },
            markdown = { "vale" },
            html = { "htmlhint" },
            css = { "stylelint" },
            scss = { "stylelint" },
            yaml = { "yamllint" },
            json = { "jsonlint" },
        },
    },
    config = function(_, opts)
        local lint = require("lint")
        
        -- Merge with LazyVim's default linters
        for ft, linters in pairs(opts.linters_by_ft) do
            lint.linters_by_ft[ft] = lint.linters_by_ft[ft] or {}
            vim.list_extend(lint.linters_by_ft[ft], linters)
        end

        -- Add codespell as a global linter
        vim.api.nvim_create_autocmd({ "BufWritePost" }, {
            callback = function()
                require("lint").try_lint("codespell")
            end,
        })
    end,
}
