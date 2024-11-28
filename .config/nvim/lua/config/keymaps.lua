-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here

-- Perusing code faster with K and J
-- vim.keymap.set({ "n", "v" }, "K", "5k", { noremap = true, desc = "Up faster" })
-- vim.keymap.set({ "n", "v" }, "J", "5j", { noremap = true, desc = "Down faster" })

-- This part taken from: https://github.com/craftzdog/dotfiles-public/blob/master/.config/nvim/lua/config/keymaps.lua
local map = vim.keymap.set
local opts = { noremap = true, silent = true }

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

-- Remap Enter to Paste new Line & get back to Normal mode
map("n", "<Return>", "o<ESC>")
