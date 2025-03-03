-- Display latest package versions in package.json as virtual text
return {
    {
        "vuki656/package-info.nvim",
        dependencies = { "MunifTanjim/nui.nvim" },
        ft = "json",

        keys = {
            { "<leader>ps", "<cmd>lua require('package-info').show()<cr>", desc = "PackageInfo show" },
            { "<leader>pd", "<cmd>lua require('package-info').delete()<cr>", desc = "PackageInfo delete" },
            { "<leader>pi", "<cmd>lua require('package-info').install()<cr>", desc = "PackageInfo install" },
            {
                "<leader>pc",
                "<cmd>lua require('package-info').change_version()<cr>",
                desc = "PackageInfo change version",
            },
        },

        config = function()
            require("package-info").setup({
                autostart = false,
                package_manager = "npm",
                hide_up_to_date = true,
                colors = {
                    outdated = "#db4b4b",
                },
            })
        end,
    },
}
