return {
  -- add gruvbox
  { "ellisonleao/gruvbox.nvim" },

  {
    "rebelot/kanagawa.nvim",
    config = function()
      require("kanagawa").setup({
        theme = "wave",
        background = {
          dark = "dragon", -- wave/lotus/dragon
          light = "lotus",
        },
      })
    end,
  },

  {
    "folke/tokyonight.nvim",
    lazy = true,
    opts = { style = "moon" },
  },

  {
    "neanias/everforest-nvim",
    version = false,
    lazy = false,
    priority = 1000, -- make sure to load this before all the other start plugins
    -- Optional; default configuration will be used if setup isn't called.
    config = function()
      require("everforest").setup({
        transparent_background_level = 1,
      })
    end,
  },

  { "bluz71/vim-moonfly-colors", name = "moonfly", lazy = false, priority = 1000 },

  {
    "cpea2506/one_monokai.nvim",
    enabled = false,
    config = function()
      require("one_monokai").setup({
        transparent = true, -- enable transparent window
        -- colors = {
        -- lmao = "#ffffff", -- add new color
        -- pink = "#ec6075", -- replace default color
        -- },
        themes = function(colors)
          -- change highlight of some groups,
          -- the key and value will be passed respectively to "nvim_set_hl"
          return {
            Normal = { bg = colors.lmao },
            DiffChange = { fg = colors.white:darken(0.3) },
            ErrorMsg = { fg = colors.pink, standout = true },
            ["@lsp.type.keyword"] = { link = "@keyword" },
          }
        end,
        italics = false, -- disable italics
      })
    end,
  },

  {
    "tjdevries/colorbuddy.nvim",
    -- colorscheme colorbuddy
    -- colorscheme gruvbuddy
  },

  {
    "tiagovla/tokyodark.nvim",
    enabled = false,
    opts = {
      -- custom options here
    },
    config = function(_, opts)
      require("tokyodark").setup(opts) -- calling setup is optional
      vim.cmd([[colorscheme tokyodark]])
    end,
  },

  { "danwlker/primeppuccin", priority = 1000 },

  { "yorumicolors/yorumi.nvim" },

  {
    "myagko/nymph",
    branch = "Nvim",
    -- opts = {
    --     transparent = true,
    -- }
  },

  -- nightfox/terafox/carbonfox/nordfox/duskfox/dawnfox/dayfox
  {
    "EdenEast/nightfox.nvim",
    config = function()
      require("nightfox").setup({
        options = {
          transparent = false,
        },
      })
    end,
  },

  -- sonokai/𝐀𝐭𝐥𝐚𝐧𝐭𝐢𝐬/𝐀𝐧𝐝𝐫𝐨𝐦𝐞𝐝𝐚/𝐒𝐡𝐮𝐬𝐢𝐚/𝐌𝐚𝐢𝐚/𝐄𝐬𝐩𝐫𝐞𝐬𝐬𝐨
  { "sainnhe/sonokai" },

  {
    "xero/miasma.nvim",
    lazy = false,
    priority = 1000,
    config = function()
      -- vim.cmd("colorscheme miasma")
    end,
  },

  {
    "killitar/obscure.nvim",
    lazy = false,
    priority = 1000,
    opts = {},
  },

  { "qaptoR-nvim/chocolatier.nvim", priority = 1000, config = true, opts = {} },

  { "fcancelinha/nordern.nvim", branch = "master", priority = 1000 },

  {
    "craftzdog/solarized-osaka.nvim",
    branch = "osaka",
    lazy = true,
    priority = 1000,
    opts = function()
      return {
        transparent = true,
      }
    end,
  },

  {
    "eldritch-theme/eldritch.nvim",
    lazy = true,
    name = "eldritch",
  },

  ----------------------------------
  -- Configure LazyVim to load theme
  {
    "LazyVim/LazyVim",
    opts = {
      colorscheme = "solarized-osaka", --"everforest",
    },
  },
}
