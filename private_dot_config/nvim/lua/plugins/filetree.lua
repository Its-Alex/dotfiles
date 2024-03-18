return {
    "nvim-tree/nvim-tree.lua",
    version = "1.3.x",
    lazy = false,
    dependencies = {
        "nvim-tree/nvim-web-devicons",
    },
    config = function()
        require("nvim-tree").setup({
            filters = {
                dotfiles = false,
            },
        })
    end,
}
