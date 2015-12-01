execute pathogen#infect()
syntax on
filetype plugin indent on

"Show line number
:set number

""Smarter tab extension
let g:airline#extensions#tabline#enabled = 1
let g:airline_powerline_fonts = 1

""JSX Syntax
let g:jsx_ext_required = 0

" Default settings
set ts=2 sts=2 sw=2 expandtab

"Indent guides
let g:indent_guides_start_level = 2
let g:indent_guides_guide_size = 1

" Automatically removing all trailing whitespace
autocmd BufWritePre * :%s/\s\+$//e

"Abbreviations
ab pry require 'pry';binding.pry

set wildignore=*.swp,*.bak,*.pyc,*.class

set nobackup
set noswapfile

" show when searching
set incsearch

" highlight all occurrences when searching
set hlsearch

" Powerline
set term=xterm-256color
set termencoding=utf-8
set fillchars+=stl:\ ,stlnc:\
set encoding=utf-8
set t_Co=256
let g:Powerline_symbols = 'fancy'
set guifont=Inconsolata\ for\ Powerline:h15

" Treat hamlc as haml
au BufRead,BufNewFile *.hamlc set ft=haml

" unmapping arrow keys
nnoremap <up> <nop>
nnoremap <down> <nop>
nnoremap <left> <nop>
nnoremap <right> <nop>
inoremap <up> <nop>
inoremap <down> <nop>
inoremap <left> <nop>
inoremap <right> <nop>

" Mac
if has("gui_running")
  let s:uname = system("uname")
  if s:uname == "Darwin\n"
    set guifont=Inconsolata\ for\ Powerline:h15
  endif
endif
