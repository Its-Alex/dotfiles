return {
    "nvim-treesitter/nvim-treesitter",
    build = ":TSUpdate",
    lazy = false,
    -- nvim-treesitter is used ONLY as a parser installer.
    -- Highlighting, indent, folds and incremental selection
    -- are handled natively by Neovim 0.12 (see plugin/treesitter.lua).
    config = function()
        require('nvim-treesitter.configs').setup({
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
