-- Display latest package versions in package.json as virtual text
return {
    {
        "vuki656/package-info.nvim",
        requires = "MunifTanjim/nui.nvim",
        package_manager = "npm",
        autostart = true,
        colors = {
            up_to_date = "#3C4048",
            outdated = "#d19a66",
            invalid = "#ee4b2b",
        },

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
