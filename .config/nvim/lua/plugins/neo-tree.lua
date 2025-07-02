return {
    {
        "nvim-neo-tree/neo-tree.nvim", -- <-- ИСПРАВЛЕНО НА ПРАВИЛЬНЫЙ РЕПОЗИТОРИЙ
        branch = "v3.x", -- Убедитесь, что вы используете v3.x, это текущая стабильная ветка
        dependencies = {
            "nvim-lua/plenary.nvim",
            "nvim-tree/nvim-web-devicons", -- Если вы используете иконки
            "MunifTanjim/nui.nvim",
        },
        opts = {
            window = {
                mappings = {
                    ["_"] = "toggle_selection", -- Ваша новая привязка
                },
            },
        },
    },
}
