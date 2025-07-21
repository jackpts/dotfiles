-- :Marko 	Open the marks popup
-- :MarkoToggleVirtual 	 Toggle virtual text marks on/off
-- Then > Enter - Jump to mark, d - Delete mark, q or Esc - Close popup

return {
    {
        "developedbyed/marko.nvim",
        config = function()
            require("marko").setup({
                width = 100,
                height = 100,
                border = "rounded",
                title = " Marks ",
            })
        end,
    },
}
