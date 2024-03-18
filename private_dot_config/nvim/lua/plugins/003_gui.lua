return {
    -- add dracula
    { "Mofiqul/dracula.nvim" },
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
    },
    {
        "HiPhish/rainbow-delimiters.nvim"
    },
    {
        "lukas-reineke/indent-blankline.nvim",
        main = "ibl",
        opts = {},
        config = function()
            require("ibl").setup()
        end,
    },
    {
        "rcarriga/nvim-notify",
        config = function ()
            vim.notify = require("notify")
        end
    },
}
