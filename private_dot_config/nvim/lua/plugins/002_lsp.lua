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
                    -- Lua
                    { 'lua_ls', version = '3.18.2'},
                    -- Vim
                    { 'vim-language-server', version = '2.3.1'},
                    -- Yaml
                    { 'yamlls', version = '1.23.0'},
                    -- Json
                    { 'json-lsp', version = '4.10.0'},
                    -- SQL
                    { 'sqlls', version = '1.7.1'},
                    { 'sql-formatter', version = '15.8.1'},
                    -- Bash
                    { 'shellcheck', version = 'v0.11.0'},
                    { 'bash-language-server', version = '5.6.0'},
                    -- Helm
                    { 'helm-ls', version = 'v0.5.4'},
                    -- Markdown
                    { 'markdownlint-cli2', version = '0.22.1'},
                    -- Ansible
                    { 'ansible-language-server', version = '26.6.0'},
                    -- Terraform
                    { 'terraform-ls', version = 'v0.38.7'},
                    -- CSS
                    { 'css-lsp', version = '4.10.0'},
                    -- HTLM
                    { 'html-lsp', version = '4.10.0'},
                    -- Python
                    { 'pyright', version = '1.1.410'},
                    { 'autopep8', version = '2.3.2'},
                    { 'flake8', version = '7.3.0'},
                    { 'isort', version = '8.0.1'},
                    -- Javascript
                    { 'prettierd', version = '0.28.0'},
                    { 'eslint_d', version = '15.0.2'},
                    -- Svelte
                    { 'svelte-language-server', version = '0.18.2'},
                    -- Typescript
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
