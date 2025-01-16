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
                    { 'lua_ls', version = '3.13.5'},
                    -- Vim
                    { 'vim-language-server', version = '2.3.1'},
                    -- Yaml
                    { 'yamlls', version = '1.15.0'},
                    -- Json
                    { 'json-lsp', version = '4.10.0'},
                    -- SQL
                    { 'sqlls', version = '1.7.1'},
                    { 'sql-formatter', version = '15.4.9'},
                    -- Bash
                    { 'shellcheck', version = 'v0.10.0'},
                    { 'bash-language-server', version = '5.3.4'},
                    -- Helm
                    { 'helm-ls', version = 'v0.1.1'},
                    -- Markdown
                    { 'markdownlint-cli2', version = '0.17.1'},
                    -- Ansible
                    { 'ansible-language-server', version = '1.2.3'},
                    -- Terraform
                    { 'terraform-ls', version = 'v0.36.3'},
                    -- CSS
                    { 'css-lsp', version = '4.10.0'},
                    -- HTLM
                    { 'html-lsp', version = '4.10.0'},
                    -- Python
                    { 'pyright', version = '1.1.392'},
                    { 'autopep8', version = '2.3.2'},
                    { 'flake8', version = '7.1.1'},
                    { 'isort', version = '5.13.2'},
                    -- Javascript
                    { 'prettierd', version = '0.26.0'},
                    { 'eslint_d', version = '14.3.0'},
                    -- Svelte
                    { 'svelte-language-server', version = '0.17.10'},
                    -- Typescript
                    { 'typescript-language-server', version = '4.3.3'}
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
            require("mason-lspconfig").setup()
            require("mason-lspconfig").setup_handlers {
                function(server_name)
                    require("lspconfig")[server_name].setup {}
                end,

                -- Allow lua to be aware of vim in neovim
                ["lua_ls"] = function()
                    local lspconfig = require('lspconfig')

                    lspconfig.lua_ls.setup {
                        settings = {
                            Lua = {
                                runtime = {
                                    -- Tell the language server which version of Lua you're using
                                    -- (most likely LuaJIT in the case of Neovim)
                                    version = 'LuaJIT',
                                },
                                diagnostics = {
                                    -- Get the language server to recognize the `vim` global
                                    globals = {
                                        'vim',
                                        'require'
                                    },
                                    disable = { 'missing-fields' }
                                },
                                workspace = {
                                    -- Make the server aware of Neovim runtime files
                                    library = vim.api.nvim_get_runtime_file("", true),
                                },
                            },
                        },
                    }
                end
            }
        end
    },
}
