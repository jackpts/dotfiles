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
    -- add tsserver and setup with typescript.nvim instead of lspconfig
    {
        "neovim/nvim-lspconfig",
        dependencies = {
            "mason-org/mason-lspconfig.nvim",
            "jose-elias-alvarez/typescript.nvim",
            init = function()
                require("lazyvim.util").lsp.on_attach(function(_, buffer)
          -- stylua: ignore
          vim.keymap.set( "n", "<leader>co", "TypescriptOrganizeImports", { buffer = buffer, desc = "Organize Imports" })
                    vim.keymap.set("n", "<leader>cR", "TypescriptRenameFile", { desc = "Rename File", buffer = buffer })
                end)
            end,
        },
        event = { "BufReadPre", "BufNewFile" },
        ---@class PluginLspOpts
        opts = {
            inlay_hints = {
                enabled = true,
            },
            servers = {
                tsserver = {},

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
                -- example to setup with typescript.nvim
                tsserver = function(_, opts)
                    require("typescript").setup({ server = opts })
                    return true
                end,
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
            },

            -- add custom diagnostics
            diagnostics = {
                -- virtual_text = false, -- Disable default virtual text
            },
        },
    },
}
