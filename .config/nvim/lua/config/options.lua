-- Options are automatically loaded before lazy.nvim startup
-- Default options that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua
-- Add any additional options here

local opt = vim.opt

vim.o.swapfile = false -- disable swapfiles because they are fucking garbage
vim.o.shell = "/usr/bin/fish"
opt.relativenumber = false
opt.clipboard = "unnamedplus" -- Use system clipboard
opt.tabstop = 4
opt.shiftwidth = 4
opt.autoindent = true
opt.smartcase = true
opt.incsearch = true
opt.autoindent = true
opt.fillchars = {eob = " "}

vim.wo.wrap = false
vim.g.autoformat = false
vim.o.signcolumn = "yes:1"
