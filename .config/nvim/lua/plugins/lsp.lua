--  from: https://www.devas.life/effective-neovim-setup-for-web-development-towards-2024/

return {
    -- tools
    {
        "mason-org/mason.nvim",
        opts = function(_, opts)
            vim.list_extend(opts.ensure_installed, {
                "stylua",
                "selene",
                "luacheck",
                "shellcheck",
                "shfmt",
                -- "tailwindcss-language-server",
                "typescript-language-server",
                "css-lsp",
            })
        end,
    },
    -- ts_ls via lspconfig
    {
        "neovim/nvim-lspconfig",
        dependencies = {
            "mason-org/mason-lspconfig.nvim",
        },
        event = { "BufReadPre", "BufNewFile" },
        ---@class PluginLspOpts
        opts = {
            inlay_hints = {
                enabled = true,
            },
            servers = {
                ts_ls = {},

                --[[                 basedpyright = {
                    settings = {
                        pyright = {
                            disableOrganizeImports = true, -- Using Ruff
                        },
                        python = {
                            analysis = {
                                ignore = { "*" }, -- Using Ruff
                            },
                        },
                    },
                }, ]]

                --[[                 yaml = {
                    settings = {
                        validate = true,
                        schemaStore = {
                            enable = false,
                            url = "",
                        },
                        schemas = {
                            ["https://json.schemastore.org/github-workflow.json"] = "/.github/workflows/*",
                        },
                    },
                }, ]]
            },

            -- you can do any additional lsp server setup here
            -- return true if you don't want this server to be setup with lspconfig
            ---@type table<string, fun(server:string, opts:_.lspconfig.options):boolean?>
            setup = {
                -- Specify * to use this function as a fallback for any server
                -- ["*"] = function(server, opts) end,
            },

            config = function()
                local lspconfig = require("lspconfig")
                local mason = require("mason")

                vim.lsp.handlers["textDocument/signatureHelp"] = vim.lsp.with(vim.lsp.handlers.signature_help, {
                    title = "signature",
                    border = "single",
                })

                mason.setup()

                -- lspconfig.basedpyright.setup({})
                -- lspconfig.yamlls.setup({})
                -- lspconfig.terraformls.setup({})
                lspconfig.ts_ls.setup({})
                lspconfig.eslint.setup({})
                lspconfig.html.setup({})
                lspconfig.cssls.setup({})
                -- lspconfig.kotlin_language_server.setup({})
            end,
            keys = {
                { "<leader>gD", "<cmd>lua vim.lsp.buf.declaration()<cr>", { noremap = true, silent = true } },
                { "<leader>co", "<cmd>lua vim.lsp.buf.code_action({ context = { only = { 'source.organizeImports' } }, apply = true })<cr>", desc = "Organize Imports" },
            },

            -- add custom diagnostics
            diagnostics = {
                -- virtual_text = false, -- Disable default virtual text
            },
        },
    },
}
