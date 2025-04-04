-- Additional configurations from nvim-treesitter
local configs = require("nvim-treesitter.configs")
local rainbow_test = { { { { { {} } } } } }

return {
    -- since `vim.tbl_deep_extend`, can only merge tables and not lists, the code above
    -- would overwrite `ensure_installed` with the new value.
    -- If you'd rather extend the default config, use the code below instead:
    {
        "nvim-treesitter/nvim-treesitter",
        build = ":TSUpdate",
        opts = function(_, opts)
            -- add tsx and treesitter
            vim.list_extend(opts.ensure_installed, {
                "bash",
                "go",
                "html",
                "java",
                "javascript",
                "css",
                "json",
                "lua",
                "markdown",
                "markdown_inline",
                "python",
                "prisma",
                "svelte",
                "query",
                "regex",
                "rust",
                "sql",
                "tsx",
                "typescript",
                "vim",
                "vimdoc",
                "yaml",
                "markdown",
                "markdown_inline",
                "graphql",
                "dockerfile",
                "gitignore",
            })
        end,
        config = function()
            configs.setup({
                auto_install = true,
                highlight = { enable = true },
                indent = { enable = true },
                rainbow = { enable = true },
            })
        end,
    },

    {
        "nvim-treesitter/nvim-treesitter-context",
        event = { "BufReadPre", "BufNewFile" },
        dependencies = "nvim-treesitter/nvim-treesitter",
        opts = {
            max_lines = 1,
        },
    },

    {
        "windwp/nvim-ts-autotag",
        ft = { "html", "xml" },
    },
}
