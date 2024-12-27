-- Options are automatically loaded before lazy.nvim startup
-- Default options that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua
-- Add any additional options here

vim.o.swapfile = false -- disable swapfiles because they are fucking garbage
vim.o.shell = "/usr/bin/zsh"
vim.opt.relativenumber = false
vim.opt.clipboard = "unnamedplus" -- Use system clipboard
vim.opt.tabstop = 4
vim.opt.shiftwidth = 4
vim.opt.autoindent = true
