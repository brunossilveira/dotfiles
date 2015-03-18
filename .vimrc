execute pathogen#infect()
syntax on
filetype plugin indent on

"Show line number
:set number

""Start NERDTree automatically
autocmd StdinReadPre * let s:std_in=1
autocmd VimEnter * if argc() == 0 && !exists("s:std_in") | NERDTree | endif

""Ctrl N to open NerdTree
map <C-n> :NERDTreeToggle<CR>

""Close vim only if there is just a NerdTree
autocmd bufenter * if (winnr("$") == 1 && exists("b:NERDTreeType") && b:NERDTreeType == "primary") | q | endif

""Smarter tab extension
let g:airline#extensions#tabline#enabled = 1

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
