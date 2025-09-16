-- bootstrap lazy.nvim, LazyVim and your plugins
require("config.lazy")
require("config.diagnostic")

require("neo-tree").setup({
    filesystem = {
        filtered_items = {
            hide_dotfiles = false, -- Show hidden files (dotfiles)
            hide_gitignored = true, -- Show files ignored by git
            visible = true,
        },
        -- follow_current_file = true,
        follow_current_file = { enabled = true }, -- Replace with table
    },
    buffers = {
        -- follow_current_file = true, -- This will find and focus the file in the active buffer every
        follow_current_file = { enabled = true }, -- Replace with table
        group_empty_dirs = true, -- when true, empty folders will be grouped together
        show_unloaded = true,
    },
    -- git_status = {
        -- windsnacksow = snacks({
            -- position = "float",
            -- mappings = {
                -- ["A"] = "git_add_file",
                -- ["a"] = "git_add_all",
                -- ["X"] = "git_restore_file",
                -- ["x"] = "git_restore_all",
                -- ["u"] = "git_unstage_file",
                -- ["D"] = "git_delete_file",
                -- ["r"] = "git_rename_file",
                -- ["<C-r>"] = "git_refresh_file",
                -- ["o"] = "system_open",
                -- ["y"] = "copy_to_clipboard",
                -- ["I"] = "show_file_details",
            -- },
        -- }),
    -- },
})

-- vim.api.nvim_create_autocmd("BufEnter", {
--     callback = function()
--         local filepath = vim.fn.expand("%:p:h") -- Get the directory of the current file
--         require("neo-tree.command").execute({
--             action = "show",
--             path = filepath,
--         })
--     end,
-- })

-- auto-create file if not exist
vim.api.nvim_create_autocmd("BufEnter", {
    pattern = "*",
    callback = function()
        local file = vim.fn.expand("%")
        if file ~= "" and not vim.bo.readonly and vim.fn.filereadable(file) == 0 then
            vim.cmd("silent! !touch " .. file)
        end
    end,
})



-- optionally enable 24-bit colour
vim.opt.termguicolors = true
