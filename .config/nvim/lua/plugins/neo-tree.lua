return {
    {
        "nvim-neo-tree/neo-tree.nvim",
        branch = "v3.x",
        dependencies = {
            "nvim-lua/plenary.nvim",
            "nvim-tree/nvim-web-devicons",
            "MunifTanjim/nui.nvim",
        },
        opts = {
            filesystem = {
                filtered_items = {
                    hide_dotfiles = false, -- Show hidden files (dotfiles)
                    hide_gitignored = true, -- Show files ignored by git
                    visible = true,
                },
                follow_current_file = {
                    enabled = true,
                },
            },
            buffers = {
                follow_current_file = {
                    enabled = true, -- This will find and focus the file in the active buffer every
                },
                group_empty_dirs = true, -- when true, empty folders will be grouped together
                show_unloaded = true,
            },
            git_status = {
                window = {
                    position = "float",
                    mappings = {
                        ["A"] = "git_add_file",
                        ["a"] = "git_add_all",
                        ["X"] = "git_restore_file",
                        ["x"] = "git_restore_all",
                        ["u"] = "git_unstage_file",
                        ["D"] = "git_delete_file",
                        ["r"] = "git_rename_file",
                        ["<C-r>"] = "git_refresh_file",
                        ["o"] = "system_open",
                        ["y"] = "copy_to_clipboard",
                        ["I"] = "show_file_details",
                    },
                },
            },
            window = {
                mappings = {
                    ["_"] = "toggle_node",
                },
            },
        },
        config = function(_, opts)
            require("neo-tree").setup(opts)

            -- Open Neo-tree once on startup after UI is ready (avoids invalid window id errors)
            vim.api.nvim_create_autocmd("VimEnter", {
                once = true,
                callback = function()
                    -- Skip when Snacks dashboard or special buffers are active, or no file is loaded
                    local ft = vim.bo.filetype
                    if ft == "snacks_dashboard" or (type(ft) == "string" and ft:match("^snacks")) or vim.fn.expand("%") == "" then
                        return
                    end

                    local filepath = vim.fn.expand("%:p:h")
                    -- Use focus + jump back instead of action=show to avoid plugin's window restore bug
                    vim.defer_fn(function()
                        local ok, cmd = pcall(require, "neo-tree.command")
                        if not ok then return end
                        -- Open/focus the tree, then return to previous window safely
                        cmd.execute({ action = "focus", path = filepath })
                        vim.schedule(function()
                            pcall(vim.cmd, "wincmd p")
                        end)
                    end, 30)
                end,
            })
        end,
    },
}
