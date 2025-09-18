return {
  "nvimtools/none-ls.nvim",
  config = function()
    local null_ls = require("null-ls")

    null_ls.setup({
      sources = {
        -- Use Prettier for formatting
        -- null_ls.builtins.formatting.prettier,
        null_ls.builtins.formatting.prettier.with({
          extra_args = { "--config-precedence", "prefer-file", "--parser", "json" },
        }),
        -- Use ESLint for diagnostics
        null_ls.builtins.diagnostics.eslint,
        -- Add any other tools you want to integrate
        null_ls.builtins.formatting.stylua, -- For Lua formatting
        null_ls.builtins.diagnostics.flake8, -- For Python diagnostics
      },
      -- Optional: Configure on_attach to set up key mappings
      --[[       on_attach = function(_client, bufnr)
        -- Key mappings for formatting and diagnostics
        local function buf_set_keymap(...)
          vim.api.nvim_buf_set_keymap(bufnr, ...)
        end
        buf_set_keymap(
          "n",
          "<leader>f",
          "<cmd>lua vim.lsp.buf.formatting_sync()<CR>",
          { noremap = true, silent = true }
        )
        buf_set_keymap(
          "n",
          "<leader>d",
          "<cmd>lua vim.lsp.diagnostic.show_line_diagnostics()<CR>",
          { noremap = true, silent = true }
        )
      end, ]]
    })
  end,
}
