local map = vim.keymap.set
local function get_default_branch_name()
    local res = vim.system({ "git", "rev-parse", "--verify", "main" }, { capture_output = true }):wait()
    return res.code == 0 and "main" or "master"
end

return {
    -- Diff Git View open in New Buffer
    -- Get started by opening file history for:
    -- >> The current branch: :DiffviewFileHistory
    -- >> The current file: :DiffviewFileHistory %
    -- Calling :DiffviewOpen with no args opens a new Diffview that compares against the current index
    -- You can also provide any valid git rev to view: :DiffviewOpen HEAD~2
    --
    -- Detailed config taken from: https://github.com/bphkns/dotfiles/blob/main/nvim/.config/nvim/lua/plugins/diffview.lua
    {
        "sindrets/diffview.nvim",
        dependencies = {
            "nvim-lua/plenary.nvim",
        },
        -- lazy = true,
        keys = {
            { ",gd", "<cmd>DiffviewOpen<cr>", desc = "Open diffview" },
            { ",gc", "<cmd>DiffviewClose<cr>", desc = "Close diffview" },
            { ",gr", "<cmd>DiffviewFileHistory<cr>", desc = "Repo history" },
            { ",gf", "<cmd>DiffviewFileHistory --follow %<cr>", desc = "File history" },
            { ",gv", "<Esc><Cmd>'<,'>DiffviewFileHistory --follow<CR>", mode = "v", desc = "Range history" },
            { ",gl", "<Cmd>.DiffviewFileHistory --follow<CR>", desc = "Line history" },
            {
                ",gm",
                function()
                    vim.cmd("DiffviewOpen " .. get_default_branch_name())
                end,
                desc = "Compare local main",
            },
            {
                ",gM",
                function()
                    vim.cmd("DiffviewOpen HEAD..origin/" .. get_default_branch_name())
                end,
                desc = "Compare remote main",
            },
        },
    },

    -- Git signs
    {
        "lewis6991/gitsigns.nvim",
        config = function()
            require("gitsigns").setup()

            map("n", "<leader>gp", ":Gitsigns preview_hunk<CR>", {})
            map("n", "<leader>gt", ":Gitsigns toggle_current_line_blame<CR>", {})
        end,
    },

    -- Interface for Neovim, inspired by Magit
    -- :Neogit             " Open the status buffer in a new tab
    -- :Neogit cwd=<cwd>   " Use a different repository path
    -- :Neogit cwd=%:p:h   " Uses the repository of the current file
    -- :Neogit kind=<kind> " Open specified popup directly
    -- :Neogit commit      " Open commit popup
    -- now Neogit call mapped in keymaps.lua as <Leader>gn !
    {
        "NeogitOrg/neogit",
        dependencies = {
            "nvim-lua/plenary.nvim", -- required
            "sindrets/diffview.nvim", -- optional - Diff integration

            -- Only one of these is needed.
            "nvim-telescope/telescope.nvim", -- optional
            "ibhagwan/fzf-lua", -- optional
            "echasnovski/mini.pick", -- optional
        },
        -- config = true,
        config = function()
            require("neogit").setup({
                kind = "floating",
            })
        end,
    },

    -- Flog - Git branch viewer
    {
        "rbong/vim-flog",
        lazy = true,
        cmd = { "Flog", "Flogsplit", "Floggit" },
        dependencies = {
            "tpope/vim-fugitive",
        },
    },

    -- git blame
    {
        "f-person/git-blame.nvim",
        event = "VeryLazy",
        opts = {
            enabled = true,
            message_template = "        <summary> • <date> • <author> • <<sha>>",
            date_format = "%d.%m.%Y %H:%M",
            virtual_text_column = 1,
            message_when_not_committed = "      Oh please, commit this!",
            delay = 2000,
        },
        cmd = { "GitBlameToggle", "GitBlameEnable", "GitBlameDisable" },
    },

    -- Run the command :Unified to display the diff against HEAD and open the file tree.
    -- To show the diff against a specific commit, run :Unified <commit_ref>, for example :Unified HEAD~1
    {
        "axkirillov/unified.nvim",
        opts = {
            -- your configuration comes here
        },
    },
}
