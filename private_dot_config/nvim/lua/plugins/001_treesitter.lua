return {
    "nvim-treesitter/nvim-treesitter",
    build = ":TSUpdate",
    lazy = false,
    config = function()
        require('nvim-treesitter').setup({
            ensure_installed = {
                "lua", "vim", "vimdoc", "bash",
                "helm", "hcl", "python", "css", "html",
                "typescript", "javascript", "graphql", "svelte",
                "go", "markdown", "markdown_inline", "ninja", "sql",
                "json", "toml", "yaml",
            },
        })
    end
}
