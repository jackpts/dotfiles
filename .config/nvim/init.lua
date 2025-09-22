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
        follow_current_file = true,
    },
    buffers = {
        follow_current_file = true, -- This will find and focus the file in the active buffer every
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
})

vim.api.nvim_create_autocmd("BufEnter", {
    callback = function()
        -- Skip when Snacks buffers are active or no file is loaded
        local ft = vim.bo.filetype
        if ft == "snacks_dashboard" or ft:match("^snacks") or vim.fn.expand("%") == "" then
            return
        end

        local filepath = vim.fn.expand("%:p:h")
        require("neo-tree.command").execute({
            action = "show",
            path = filepath,
        })
    end,
})

-- auto-create file if not exist
vim.api.nvim_create_autocmd("BufEnter", {
  pattern = "*",
  callback = function()
    local file = vim.fn.expand("%")
    if file ~= "" and not vim.bo.readonly and vim.fn.filereadable(file) == 0 then
      vim.cmd("silent! !touch " .. file)
    end
  end
})


-- optionally enable 24-bit colour
vim.opt.termguicolors = true

