return {
    "nvim-treesitter/nvim-treesitter",
    build = ":TSUpdate",
    config = function()
        require('nvim-treesitter.configs').setup({
            ensure_installed = {
                -- Lua
                "lua",
                -- Vim
                "vim",
                "vimdoc",
                -- Bash
                "bash",
                -- Helm
                'helm',
                -- HCL
                'hcl',
                -- Python
                "python",
                -- CSS
                "css",
                -- HTML
                "html",
                -- Javascript
                "typescript",
                "javascript",
                -- Graphql
                "graphql",
                -- Svelte
                "svelte",
                -- Golang
                "go",
                -- Markdown
                "markdown",
                -- Ninja
                "ninja",
                -- Data exchange format
                "json",
                "toml",
                "yaml",
            },
            auto_install = false,
            sync_install = true,
            highlight = {
                enable = true,
                additional_vim_regex_highlighting = true,
            },
            indent = {
                enable = true
            },
            incremental_selection = {
                enable = true
            },
        })
    end
}
