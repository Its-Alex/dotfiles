-- Ruler and lines
vim.opt.ruler = true
vim.opt.number = true
vim.opt.colorcolumn = '80'

-- Spell check
vim.opt.spelllang = 'en'

-- Spaces and indents
vim.opt.softtabstop = -1
vim.opt.shiftwidth = 0
vim.opt.smarttab = true
vim.opt.expandtab = true
vim.opt.shiftround = true
vim.opt.tabstop = 4
vim.opt.softtabstop = 0
vim.opt.autoindent = true

-- Do not wrap lines. Allow long lines to extend as far as the line goes.
vim.opt.wrap = false

-- While searching though a file incrementally highlight matching characters as you type.
vim.opt.incsearch = true

-- Ignore capital letters during search.
vim.opt.ignorecase = true

-- Override the ignorecase option if searching for capital letters.
-- This will allow you to search specifically for capital letters.
vim.opt.smartcase = true

-- Do not save backup files.
vim.opt.backup = false

-- Use highlighting when doing a search.
vim.opt.hlsearch = true

-- Enable auto completion menu after pressing TAB.
vim.opt.wildmenu = true

-- Make wildmenu behave like similar to Bash completion.
vim.opt.wildmode = 'list:longest'

-- Disable swapfiles
vim.opt.swapfile = false

-- Colorscheme
vim.opt.termguicolors = true
vim.cmd.colorscheme('dracula')

-- Clipboard
vim.api.nvim_set_option("clipboard", "unnamed")

