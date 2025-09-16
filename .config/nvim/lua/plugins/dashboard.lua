-- vim.api.nvim_create_autocmd("FileType", {
--   pattern = "snacks_dashboard",
--   callback = function()
--     -- Your custom code here that runs when the snacks dashboard filetype is set
--     -- print("Snacks Dashboard is open!")
--     shouldPlayAnimation = true
--     asciiImg = frames[1]
--   end,
-- })

vim.api.nvim_create_autocmd("DirChanged", {
  pattern = "*", -- Match any directory change
  callback = function()
    local new_dir = vim.fn.getcwd()

    -- Same logic as above for project markers
    local project_markers = { ".git", "package.json", "Cargo.toml", ".project_root" }
    local is_project_root = false

    for _, marker in ipairs(project_markers) do
      if vim.fn.findfile(marker, new_dir .. ";") ~= "" then
        is_project_root = true
        break
      end
    end

    if is_project_root then
      -- print("Changed to project directory: " .. new_dir)
      shouldPlayAnimation = false
      -- Your custom code here for when you change into a project directory
    else
      -- print("Changed to non-project directory: " .. new_dir)
      shouldPlayAnimation = false
      -- Optional: Code for when you leave a project directory
    end
  end,
})

return {
  { "nvimdev/dashboard-nvim", enabled = true },

    { "MunifTanjim/nui.nvim" }
}
