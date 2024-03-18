return {
    'nvimtools/none-ls.nvim',
    dependencies = {
        "nvim-lua/plenary.nvim",
        "nvimtools/none-ls-extras.nvim",
        "gbprod/none-ls-shellcheck.nvim"
    },
    config = function()
        local null_ls = require("null-ls")

        null_ls.setup({
            sources = {
                require("none-ls.diagnostics.eslint_d").with({ extra_filetypes = { "svelte" } }),
                require("null-ls.builtins.formatting.prettierd").with({ extra_filetypes = { "svelte" } }),
                require("none-ls-shellcheck.diagnostics").with({ extra_filetypes = { "envrc", "env" } }),
                require("none-ls-shellcheck.code_actions").with({ extra_filetypes = { "envrc", "env" } }),
            }
        })
    end
}
