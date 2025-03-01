-- previewing native LSP's goto definition, type definition, implementation, declaration and references calls in floating windows.
return {
    {
        "rmagatti/goto-preview",
        event = "BufEnter",
        config = true, -- necessary as per https://github.com/rmagatti/goto-preview/issues/88
        init = function()
            vim.keymap.set(
                "n",
                "gp",
                "<cmd>lua require('goto-preview').goto_preview_definition()<CR>",
                { noremap = true, silent = true, desc = "Goto Class" }
            )
        end,
    },
}
