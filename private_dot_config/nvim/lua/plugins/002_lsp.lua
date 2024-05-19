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
                    'lua_ls',
                    -- Vim
                    'vim-language-server',
                    -- Yaml
                    'yamlls',
                    -- Json
                    'json-lsp',
                    -- SQL
                    'sqlls',
                    'sql-formatter',
                    -- Bash
                    'shellcheck',
                    'bash-language-server',
                    -- Helm
                    'helm-ls',
                    -- Markdown
                    'markdownlint-cli2',
                    -- Ansible
                    'ansible-language-server',
                    -- Terraform
                    'terraform-ls',
                    -- CSS
                    'css-lsp',
                    -- HTLM
                    'html-lsp',
                    -- Python
                    'pyright',
                    'autopep8',
                    'flake8',
                    'isort',
                    -- Javascript
                    'prettierd',
                    'eslint_d',
                    -- Svelte
                    'svelte-language-server',
                    -- Typescript
                    'typescript-language-server'
                },
                auto_update = true,
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
