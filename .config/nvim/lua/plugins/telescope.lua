local telescope = require("telescope")

return {
    {
        "nvim-telescope/telescope.nvim",
        dependencies = {
            "nvim-telescope/telescope-fzf-native.nvim",
            "nvim-telescope/telescope-live-grep-args.nvim",
            build = "make",
            config = function()
                local lga_actions = require("telescope-live-grep-args.actions")
                telescope.setup({
                    defaults = {
                        file_ignore_patterns = {
                            "node_modules",
                            "build",
                            "dist",
                            "yarn.lock",
                            "package-lock.json",
                            ".git",
                            "lazy-lock.json",
                        },
                    },
                    extensions = {
                        live_grep_args = {
                            auto_quoting = true, -- enable/disable auto-quoting
                            mappings = { -- extend mappings
                                i = {
                                    -- ["<C-k>"] = lga_actions.quote_prompt(),
                                    -- ["<C-i>"] = lga_actions.quote_prompt({ postfix = " --iglob " }),
                                    -- freeze the current list and start a fuzzy search in the frozen list
                                    ["<C-space>"] = lga_actions.to_fuzzy_refine,
                                },
                            },
                        },
                        package_info = {
                            -- Optional theme (the extension doesn't set a default theme)
                            theme = "ivy",
                        },
                    },
                })

                telescope.load_extension("fzf")
                telescope.load_extension("live_grep_args")
                telescope.load_extension("package_info")
            end,
        },
        keys = {
            -- change a keymap
            { "<C-p>", "<cmd>Telescope find_files<CR>", desc = "Find Files" },
            -- add a keymap to browse plugin files
            {
                "<leader>fp",
                function()
                    require("telescope.builtin").find_files({ cwd = require("lazy.core.config").options.root })
                end,
                desc = "Find Plugin File",
            },
            -- This is using b because it used to be fzf's :Buffers
            {
                "<leader>fo",
                "<cmd>Telescope oldfiles<cr>",
                desc = "Recent",
            },
        },
        -- change some options
        opts = {
            --   defaults = {
            --     layout_strategy = "horizontal",
            --     layout_config = { prompt_position = "top" },
            --     sorting_strategy = "ascending",
            --     winblend = 0,
            --   },
            -- add some mappings
            defaults = {
                mappings = {
                    i = {
                        ["<C-j>"] = function(...)
                            return require("telescope.actions").move_selection_next(...)
                        end,
                        ["<C-k>"] = function(...)
                            return require("telescope.actions").move_selection_previous(...)
                        end,
                    },
                },
            },
        },
    },

    -- :Telescope media_files
    {
        "nvim-telescope/telescope-media-files.nvim",
        dependencies = {
            { "nvim-telescope/telescope.nvim" },
            { "nvim-lua/popup.nvim" },
            { "nvim-lua/plenary.nvim" },
        },
        config = function()
            telescope.setup({
                extensions = {
                    media_files = {
                        -- defaults to {"png", "jpg", "mp4", "webm", "pdf"}
                        filetypes = { "png", "webp", "jpg", "jpeg", "pdf" },
                        -- find command (defaults to `fd`)
                        find_cmd = "rg",
                    },
                },
            })

            telescope.load_extension("media_files")
        end,
    },
}
