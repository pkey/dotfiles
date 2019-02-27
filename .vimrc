" Install plugins
call plug#begin('~/.vim/plugged')
Plug 'tomasiser/vim-code-dark'
Plug 'martinda/Jenkinsfile-vim-syntax'
call plug#end()

" Colorscheme
colorscheme codedark

" Spaces and tabs
set tabstop=2
set softtabstop=2
set expandtab
set backspace=2
set shiftwidth=2
" UI
set number

" Searching
set hlsearch
set incsearch

" Additional stuff
nnoremap j gj
nnoremap k gk




