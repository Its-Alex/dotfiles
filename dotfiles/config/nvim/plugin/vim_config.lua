vim.cmd([[
    " Ruler and lines
    set ruler
    set number
    set colorcolumn=80

    " Spell check
    set spell spelllang=en
    
    " Spaces and indents 
    set softtabstop=-1
    set shiftwidth=0 smarttab
    set expandtab
    set shiftround
    set tabstop=4 softtabstop=0
    set autoindent

    " filetype Enable type file detection. Vim will be able to try to detect the type of file in use.
    " plugin Enable plugins and load plugin for the detected file type.
    " indent Load an indent file for the detected file type.
    filetype plugin indent on

    " Do not wrap lines. Allow long lines to extend as far as the line goes.
    set nowrap

    " While searching though a file incrementally highlight matching characters as you type.
    set incsearch
    
    " Ignore capital letters during search.
    set ignorecase
    
    " Override the ignorecase option if searching for capital letters.
    " This will allow you to search specifically for capital letters.
    set smartcase

    " Do not save backup files.
    set nobackup

    " Use highlighting when doing a search.
    set hlsearch

    " Enable auto completion menu after pressing TAB.
    set wildmenu
    
    " Make wildmenu behave like similar to Bash completion.
    set wildmode=list:longest

    " Global config 
    set hidden
    set ttimeoutlen=0
]])
