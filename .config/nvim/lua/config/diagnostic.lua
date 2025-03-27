-- Diagnostics custom config

vim.diagnostic.config({
    underline = {
        severity = {
            min = vim.diagnostic.severity.WARN,
        },
    },
    virtual_text = {
        -- source = true,
        source = "if_many",
        -- prefix = "󱡞", -- Could be '■', '▎', 'x', '●'
        prefix = function(diagnostic)
            local icons = {
                [vim.diagnostic.severity.ERROR] = "■ ",
                [vim.diagnostic.severity.WARN] = "□ ",
                [vim.diagnostic.severity.INFO] = "▷ ",
                [vim.diagnostic.severity.HINT] = "○ ",
            }
            return icons[diagnostic.severity]
        end,
    },
    signs = true,
    --[[  signs = {
    text = {
      [vim.diagnostic.severity.ERROR] = "",
      [vim.diagnostic.severity.WARN] = "",
      [vim.diagnostic.severity.INFO] = "",
      [vim.diagnostic.severity.HINT] = "",
    },
    priority = 20,
  }, ]]

    severity_sort = true,
    float = {
        source = true, -- Or "if_many"
        border = "rounded",
        header = { "Diagnosis:", "Title" },
        format = function(diagnostic)
            return string.format(
                "%s (%s) [%s]\n%s",
                diagnostic.message,
                diagnostic.code,
                diagnostic.source,
                diagnostic.lnum + 1 .. ":" .. diagnostic.col
            )
        end,
    },
})

vim.api.nvim_set_hl(0, "DiagnosticError", { fg = "#ff5555", bg = "#1d2021" })
vim.api.nvim_set_hl(0, "DiagnosticWarn", { fg = "#ffb86c" })
vim.api.nvim_set_hl(0, "DiagnosticInfo", { fg = "#8b99ee" })
vim.api.nvim_set_hl(0, "DiagnosticHint", { fg = "#50fa7b" })
