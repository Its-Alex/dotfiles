return {
    {
        "williamboman/mason.nvim",
        lazy = false,
        config = function()
            require("mason").setup()
        end
    },
    {
        "WhoIsSethDaniel/mason-tool-installer.nvim",
        dependencies = {
            "williamboman/mason.nvim"
        },
        config = function()
            require('mason-tool-installer').setup({
                ensure_installed = {
                    { 'lua_ls', version = '3.18.2'},
                    { 'vim-language-server', version = '2.3.1'},
                    { 'yamlls', version = '1.23.0'},
                    { 'json-lsp', version = '4.10.0'},
                    { 'sqlls', version = '1.7.1'},
                    { 'sql-formatter', version = '15.8.1'},
                    { 'shellcheck', version = 'v0.11.0'},
                    { 'bash-language-server', version = '5.6.0'},
                    { 'helm-ls', version = 'v0.5.4'},
                    { 'markdownlint-cli2', version = '0.22.1'},
                    { 'ansible-language-server', version = '26.6.0'},
                    { 'terraform-ls', version = 'v0.38.7'},
                    { 'css-lsp', version = '4.10.0'},
                    { 'html-lsp', version = '4.10.0'},
                    { 'pyright', version = '1.1.410'},
                    { 'autopep8', version = '2.3.2'},
                    { 'flake8', version = '7.3.0'},
                    { 'isort', version = '8.0.1'},
                    { 'prettierd', version = '0.28.0'},
                    { 'eslint_d', version = '15.0.2'},
                    { 'svelte-language-server', version = '0.18.2'},
                    { 'typescript-language-server', version = '5.3.0'}
                },
                auto_update = false,
                run_on_start = true
            })
        end
    },
    {
        "williamboman/mason-lspconfig.nvim",
        dependencies = {
            "williamboman/mason.nvim",
            "neovim/nvim-lspconfig"
        },
        lazy = false,
        config = function()
            -- Extend nvim-lspconfig defaults; must run before mason-lspconfig enables servers.
            vim.lsp.config("lua_ls", {
                settings = {
                    Lua = {
                        runtime = {
                            version = "LuaJIT",
                        },
                        diagnostics = {
                            globals = { "vim", "require" },
                            disable = { "missing-fields" },
                        },
                        workspace = {
                            library = vim.api.nvim_get_runtime_file("", true),
                        },
                    },
                },
            })

            require("mason-lspconfig").setup()
        end
    },
}
