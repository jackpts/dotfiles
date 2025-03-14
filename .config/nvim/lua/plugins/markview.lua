-- A highly-customisable & feature rich markdown previewer inside Neovim.
return {
    {
        "OXY2DEV/markview.nvim",
        ft = "markdown",
        enabled = false,

        dependencies = {
            "nvim-treesitter/nvim-treesitter",
            "nvim-tree/nvim-web-devicons",
        },
    },
}
