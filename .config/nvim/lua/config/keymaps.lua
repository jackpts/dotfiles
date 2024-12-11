-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here

-- Perusing code faster with K and J
-- vim.keymap.set({ "n", "v" }, "K", "5k", { noremap = true, desc = "Up faster" })
-- vim.keymap.set({ "n", "v" }, "J", "5j", { noremap = true, desc = "Down faster" })

-- This part taken from: https://github.com/craftzdog/dotfiles-public/blob/master/.config/nvim/lua/config/keymaps.lua
local map = vim.keymap.set
local opts = { noremap = true, silent = true }
local util = require("lazyvim.util")
local wk = require("which-key")

-- Select all
map("n", "<C-a>", "gg<S-v>G")

-- New tab
map("n", "te", ":tabedit")
map("n", "<tab>", ":tabnext<Return>", opts)
map("n", "<s-tab>", ":tabprev<Return>", opts)

-- Diagnostics
map("n", "<C-j>", function()
  vim.diagnostic.goto_next()
end, opts)

-- Buffer switch
-- map("n", "<C-E>", "<c-^>")
map("n", "<A-.>", ":bnext<cr>")
map("n", "<A-,>", ":bprevious<cr>")
map("n", "<A-c>", ":bdelete<cr>")
map("n", "<A-<>", "<cmd>BufferMovePrevious<cr>")
map("n", "<A->>", "<cmd>BufferMoveNext<cr>")

-- Tab to move to between buffers
if util.has("bufferline.nvim") then
  map("n", "<S-Tab>", "<cmd>BufferLineCyclePrev<cr>", { desc = "Prev buffer" })
  map("n", "<Tab>", "<cmd>BufferLineCycleNext<cr>", { desc = "Next buffer" })
else
  map("n", "<S-Tab>", "<cmd>bprevious<cr>", { desc = "Prev buffer" })
  map("n", "<Tab>", "<cmd>bnext<cr>", { desc = "Next buffer" })
end

-- Remap Enter to Paste new Line & get back to Normal mode
-- map("n", "<Return>", "o<ESC>")
-- temporary disabled 'cause it affects QuickFix list behavior

-- Duplicate a line and comment out the first line
map("n", "yc", "yy<cmd>normal gcc<CR>p")

-- From the Vim wiki: https://bit.ly/4eLAARp
-- Search and replace word under the cursor
map("n", "<Leader>r", [[:%s/\<<C-r><C-w>\>//g<Left><Left>]])

wk.add({
  { "<leader>gn", "<cmd>Neogit<cr>", desc = "Neogit" },
  { "<leader>g;", "<cmd>lua require('neogit').action('log', 'log_current')()<cr>", desc = "Neogit logs" },
  { "<leader>gd", group = "Diffview" },
  { "<leader>gdc", "<cmd>DiffviewClose<cr>", mode = { "n", "i", "v" }, desc = "Close Diffview" },
  { "<leader>gdd", "<cmd>DiffviewOpen<cr>", mode = { "n", "i", "v" }, desc = "Open Diffview" },
  { "<leader>gdf", "<cmd>DiffviewToggleFiles<cr>", mode = { "n", "i", "v" }, desc = "Toggle Diffview file view" },
  { "<leader>gdr", "<cmd>DiffviewRefresh<cr>", mode = { "n", "i", "v" }, desc = "Refresh Diffview" },
})
