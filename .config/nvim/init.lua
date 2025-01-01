-- bootstrap lazy.nvim, LazyVim and your plugins
require("config.lazy")

-- require("neo-tree").setup({
--     filesystem = {
--         filtered_items = {
--             hide_dotfiles = false, -- Show hidden files (dotfiles)
--             hide_gitignored = false, -- Show files ignored by git
--         },
--     },
-- })

-- vim.api.nvim_create_autocmd("BufEnter", {
--     callback = function()
--         local filepath = vim.fn.expand("%:p:h") -- Get the directory of the current file
--         require("neo-tree.command").execute({
--             action = "show",
--             path = filepath,
--         })
--     end,
-- })
