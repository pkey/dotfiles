" Install plugins
if empty(glob('~/.vim/autoload/plug.vim'))
  silent !curl -fLo ~/.vim/autoload/plug.vim --create-dirs
    \ https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
  autocmd VimEnter * PlugInstall --sync | source $MYVIMRC
endif
call plug#begin('~/.vim/plugged')
Plug 'dracula/vim', { 'as': 'dracula' }
Plug 'tomasiser/vim-code-dark'
Plug 'martinda/Jenkinsfile-vim-syntax'
call plug#end()

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




