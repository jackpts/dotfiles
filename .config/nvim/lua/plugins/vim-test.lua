return {
  -- from: https://github.com/vim-test/vim-test
  --[[   {
    "vim-test/vim-test",
    dependencies = {
      "preservim/vimux",
    },
    config = function()
      vim.keymap.set("n", "<leader>tt", ":TestNearest<CR>", {})
      vim.keymap.set("n", "<leader>tf", ":TestFile<CR>", {})
      vim.keymap.set("n", "<leader>ts", ":TestSuite<CR>", {})
      vim.keymap.set("n", "<leader>tl", ":TestLast<CR>", {})
      vim.keymap.set("n", "<leader>tv", ":TestVisit<CR>", {})
      vim.cmd("let test#strategy = 'vimux'")
    end,
  }, ]]

  -- from: https://gist.github.com/elijahmanor/bac05af95e1536d88a43cbfcb66c1c1d
  -- by video: https://www.youtube.com/watch?v=7Nt8n3rjfDY
  {
    "nvim-neotest/neotest",
    dependencies = {
      "nvim-neotest/nvim-nio",
      "nvim-lua/plenary.nvim",
      "antoinemadec/FixCursorHold.nvim",
      "nvim-treesitter/nvim-treesitter",
      "haydenmeade/neotest-jest",
      "marilari88/neotest-vitest",
    },
    keys = {
      {
        "<leader>tl",
        function()
          require("neotest").run.run_last()
        end,
        desc = "Run Last Test",
      },
      {
        "<leader>tL",
        function()
          require("neotest").run.run_last({ strategy = "dap" })
        end,
        desc = "Debug Last Test",
      },
      {
        "<leader>tw",
        "<cmd>lua require('neotest').run.run({ jestCommand = 'jest --watch ' })<cr>",
        desc = "Run Watch",
      },
    },
    opts = function(_, opts)
      table.insert(
        opts.adapters,
        require("neotest-jest")({
          jestCommand = "npm test --",
          jestConfigFile = "custom.jest.config.ts",
          env = { CI = true },
          cwd = function()
            return vim.fn.getcwd()
          end,
        })
      )
      table.insert(opts.adapters, require("neotest-vitest"))
    end,
  },
}
