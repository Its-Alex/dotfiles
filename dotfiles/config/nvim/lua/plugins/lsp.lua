return {
    {
        "williamboman/mason.nvim",
        lazy = false,
        config = function()
            require("mason").setup()
        end
    },
    {
        "williamboman/mason-lspconfig.nvim",
        requires = {
            "williamboman/mason.nvim"
        },
        lazy = false,
        config = function()
            require("mason-lspconfig").setup()
        end
    },
    {
        "neovim/nvim-lspconfig",
        requires = {
            "williamboman/mason.nvim",
            "williamboman/mason-lspconfig.nvim"
        },
        lazy = false,
    },
    {
        "WhoIsSethDaniel/mason-tool-installer.nvim",
        requires = {
            "williamboman/mason.nvim"
        },
        config = function()
            require('mason-tool-installer').setup({
                ensure_installed = {
                    'lua_ls',
                    'vim-language-server',
                    'sqlls',
                    'shellcheck',
                    'ansible-language-server',
                    'bash-language-server',
                    'css-lsp',
                    'html-lsp',
                    'pyright',
                    'autopep8',
                    'flake8',
                    'isort',
                    'prettierd',
                    'sql-formatter',
                    'svelte-language-server',
                    'typescript-language-server'
                },
                auto_update = true,
                run_on_start = true
            })
        end
    }
}
