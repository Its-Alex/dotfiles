return {
    "nvim-treesitter/nvim-treesitter",
    build = ":TSUpdate",
    config = function()
        require('nvim-treesitter.configs').setup({
            ensure_installed = {
                "python", "lua", "javascript", "bash", "css",
                "go", "graphql", "html", "json", "markdown",
                "ninja", "svelte", "toml",
                "vim", "yaml"
            },
            auto_install = false,
            sync_install = true,
            highlight = {
                enable = true,
                additional_vim_regex_highlighting = false,
            },
            matchup = {
                enable = true
            },
            indent = {
                enable = true
            },
            incremental_selection = {
                enable = true
            },
            autopairs = {
                enable = true
            },
            rainbow = {
                enable = true,
                extended_mode = true
            }
        })
    end
}
