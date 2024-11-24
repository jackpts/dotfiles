local map = vim.keymap.set

return {
  -- tmux vim
  { "christoomey/vim-tmux-navigator" },

  -- markdown support
  { "godlygeek/tabular" }, -- required by vim-markdown
  { "plasticboy/vim-markdown" },

  -- add jsonls and schemastore ans setup treesitter for json, json5 and jsonc
  { import = "lazyvim.plugins.extras.lang.json" },

  -- comment w/ gcc & gbc
  {
    "numToStr/Comment.nvim",
    opts = {},
  },

  -- function usage
  {
    "Wansmer/symbol-usage.nvim",
    event = "LspAttach", --BufReadPre  need run before LspAttach if you use nvim 0.9. On 0.10 use 'LspAttach'
    config = function()
      require("symbol-usage").setup({
        filetypes = {
          elixir = {
            symbol_request_pos = "start",
          },
        },
        log = { enabled = false },
      })
    end,
  },

  -- Emmet! Type <c-y>, after `html:5` for example
  -- To remap the default <C-Y> leader:
  -- let g:user_emmet_leader_key='<C-X>'  // in vimrc
  { "mattn/emmet-vim" },

  -- Highlight colors for neovim
  {
    "brenoprata10/nvim-highlight-colors",
    config = function()
      require("nvim-highlight-colors").setup({
        enable_tailwind = true,
        enable_hex = true, ---Highlight hex colors, e.g. '#FFFFFF'
        enable_short_hex = true, ---Highlight short hex colors e.g. '#fff'
        enable_rgb = true, ---Highlight rgb colors, e.g. 'rgb(0 0 0)'
        enable_hsl = true, ---Highlight hsl colors, e.g. 'hsl(150deg 30% 40%)'
        enable_var_usage = true, ---Highlight CSS variables, e.g. 'var(--testing-color)'
        enable_named_colors = true, ---Highlight named colors, e.g. 'green'
        virtual_symbol = "■",
        virtual_symbol_prefix = "",
        virtual_symbol_suffix = " ",
        render = "background",
      })
    end,
  },

  -- Better quickfix window
  -- { "kevinhwang91/nvim-bqf" },

  -- Improved UI and workflow for the Neovim quickfix
  {
    "stevearc/quicker.nvim",
    event = "FileType qf",
    opts = {},
  },

  {
    "romgrk/nvim-treesitter-context",
    config = function()
      require("treesitter-context").setup({
        enable = true, -- Enable this plugin (Can be enabled/disabled later via commands)
        throttle = true, -- Throttles plugin updates (may improve performance)
        max_lines = 0, -- How many lines the window should span. Values <= 0 mean no limit.
        patterns = { -- Match patterns for TS nodes. These get wrapped to match at word boundaries.
          default = {
            "class",
            "function",
            "method",
          },
        },
      })
    end,
  },

  -- :Telescope media_files
  {
    "nvim-telescope/telescope-media-files.nvim",
    dependencies = {
      { "nvim-telescope/telescope.nvim" },
      { "nvim-lua/popup.nvim" },
      { "nvim-lua/plenary.nvim" },
    },
    config = function()
      local telescope = require("telescope")

      telescope.setup({
        extensions = {
          media_files = {
            -- defaults to {"png", "jpg", "mp4", "webm", "pdf"}
            filetypes = { "png", "webp", "jpg", "jpeg", "pdf" },
            -- find command (defaults to `fd`)
            find_cmd = "rg",
          },
        },
      })

      telescope.load_extension("media_files")
    end,
  },

  -- Show a diff using Vim its sign columns
  { "mhinz/vim-signify" },

  -- Brackets set colored by rainbow
  { "HiPhish/nvim-ts-rainbow2" },

  -- navigate and highlight matching words
  { "andymass/vim-matchup" },

  -- Easy to find cursor
  {
    "gen740/SmoothCursor.nvim",
    config = function()
      require("smoothcursor").setup({
        type = "default",
        cursor = "",
      })
    end,
  },

  -- A better user experience for viewing and interacting with Vim marks
  {
    "chentoast/marks.nvim",
    event = "VeryLazy",
    opts = {},
  },

  -- Angular language server extra functionality for Neovim LSP
  {
    "joeveiga/ng.nvim",
    init = function()
      local opts = { noremap = true, silent = true }
      local ng = require("ng")
      map(
        "n",
        "<leader>at",
        ng.goto_template_for_component,
        vim.tbl_extend("force", opts, { desc = "Goto template for component" })
      )
      -- vim.keymap.set("n", "<leader>at", ng.goto_template_for_component, { reuse_window = true } )
      map(
        "n",
        "<leader>ac",
        ng.goto_component_with_template_file,
        vim.tbl_extend("force", opts, { desc = "Goto component w/ template file" })
      )
      map("n", "<leader>aT", ng.get_template_tcb, vim.tbl_extend("force", opts, { desc = "Get template" }))
    end,
  },

  { "nvim-treesitter/nvim-treesitter-angular" },

  -- border for noice
  {
    "folke/noice.nvim",
    opts = function(_, opts)
      opts.presets.lsp_doc_border = true
    end,
  },

  -- notify extend timeout
  {
    "rcarriga/nvim-notify",
    opts = {
      timeout = 10000,
    },
  },

  -- statusline
  {
    "nvim-lualine/lualine.nvim",
    event = "VeryLazy",
    opts = {
      options = {
        theme = "solarized_dark",
      },
    },
  },

  -- Incremental rename
  {
    "smjonas/inc-rename.nvim",
    cmd = "IncRename",
    config = true,
  },

  -- disable flash
  {
    "folke/flash.nvim",
    enabled = false,
  },
}
