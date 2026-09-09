local candidates = vim.fn.glob(vim.fn.expand("~/.windsurf/extensions/yeferyv.retronvim*/nvim/init.lua"), 0, 1)
local retronvim_init = (type(candidates) == "table" and candidates[1]) or nil

if retronvim_init and retronvim_init ~= "" then
  local ok, err = pcall(dofile, retronvim_init)
  if not ok then
    vim.notify(err, vim.log.levels.ERROR)
  end
else
  vim.notify("retronvim init.lua not found", vim.log.levels.ERROR)
end

vim.keymap.set("n", "yc", function()
  local ok, vscode = pcall(require, "vscode")
  if not ok then
    vim.notify("vscode lua API not available", vim.log.levels.ERROR)
    return
  end
  vscode.action("multiCommand.ycDuplicateAndComment")
end, { silent = true })
