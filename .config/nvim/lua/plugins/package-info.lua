-- Display latest package versions in package.json as virtual text
return {
    {
        "vuki656/package-info.nvim",
        requires = "MunifTanjim/nui.nvim",
        package_manager = "npm",

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
    },
}
