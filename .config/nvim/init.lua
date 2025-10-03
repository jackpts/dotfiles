-- bootstrap lazy.nvim, LazyVim and your plugins
require("config.lazy")
require("config.diagnostic")

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

