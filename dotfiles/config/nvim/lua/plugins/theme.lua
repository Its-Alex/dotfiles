return {
    -- add dracula
    { "Mofiqul/dracula.nvim" },

    -- Configure LazyVim to load dracula
    {
        "LazyVim/LazyVim",
        opts = {
            colorscheme = "dracula",
        },
    },

    {
        'nvim-lualine/lualine.nvim',
        dependencies = { 'nvim-tree/nvim-web-devicons' },
        config = function()
            require('lualine').setup {
                options = {
                    theme = 'dracula-nvim'
                }
            }
        end,
    }
}
