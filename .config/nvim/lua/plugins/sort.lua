-- simple command to mimic :sort and supports both line-wise and delimiter sorting
return {
    {
        "sQVe/sort.nvim",
        event = "BufReadPost",
        config = function()
            require("sort").setup()
        end,
    },
}
