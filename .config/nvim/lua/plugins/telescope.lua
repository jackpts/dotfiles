return {
    {
        "nvim-telescope/telescope.nvim",
        dependencies = {
            { "nvim-telescope/telescope-fzf-native.nvim", build = "make" },
            "nvim-telescope/telescope-live-grep-args.nvim",
            "nvim-telescope/telescope-media-files.nvim",
        },
        config = function(_, opts)
            local telescope = require("telescope")
            local lga_actions = require("telescope-live-grep-args.actions")

            opts = opts or {}
            opts.extensions = opts.extensions or {}
            opts.extensions.live_grep_args = vim.tbl_deep_extend("force", {
                auto_quoting = true,
                mappings = { i = { ["<C-space>"] = lga_actions.to_fuzzy_refine } },
            }, opts.extensions.live_grep_args or {})
            opts.extensions.package_info = vim.tbl_deep_extend("force", { theme = "ivy" }, opts.extensions.package_info or {})
            opts.extensions.media_files = vim.tbl_deep_extend("force", {
                filetypes = { "png", "webp", "jpg", "jpeg", "pdf" },
                find_cmd = "rg",
            }, opts.extensions.media_files or {})

            opts.defaults = opts.defaults or {}
            opts.defaults.file_ignore_patterns = opts.defaults.file_ignore_patterns or {
                "node_modules",
                "build",
                "dist",
                "yarn.lock",
                "package-lock.json",
                "%.git/",
                "lazy-lock.json",
            }

            telescope.setup(opts)
            pcall(telescope.load_extension, "fzf")
            pcall(telescope.load_extension, "live_grep_args")
            pcall(telescope.load_extension, "package_info")
            pcall(telescope.load_extension, "media_files")
        end,
        keys = {
            -- Files
            { "<leader><leader>", function() require('telescope.builtin').find_files({find_command = { "fd", "--type", "f", "--hidden", "--no-ignore", "--follow" }}) end, desc = "Find Files" },
            { "<C-p>", function() require('telescope.builtin').find_files({find_command = { "fd", "--type", "f", "--hidden", "--no-ignore", "--follow" }}) end, desc = "Find Files" },
            -- Grep
            {
                "<leader>/",
                function()
                    local vimgrep_args = {
                        "rg",
                        "--color=never",
                        "--no-heading",
                        "--with-filename",
                        "--line-number",
                        "--column",
                        "--smart-case",
                        "--hidden",
                        "--no-ignore",
                    }
                    local ok = pcall(function()
                        require("telescope").extensions.live_grep_args.live_grep_args({
                            vimgrep_arguments = vimgrep_args
                        })
                    end)
                    if not ok then
                        require("telescope.builtin").live_grep({
                            vimgrep_arguments = vimgrep_args
                        })
                    end
                end,
                desc = "Grep in files",
            },
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
                vimgrep_arguments = {
                    "rg",
                    "--color=never",
                    "--no-heading",
                    "--with-filename",
                    "--line-number",
                    "--column",
                    "--smart-case",
                    "--hidden",
                    "--no-ignore",
                },
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
            -- Make find_files ignore VCS and other ignore files so expected files always appear
            pickers = {
                find_files = {
                    find_command = { "fd", "--type", "f", "--hidden", "--no-ignore", "--follow" },
                    hidden = true,
                    no_ignore = true,
                    follow = true,
                },
            },
        },
    },
}
