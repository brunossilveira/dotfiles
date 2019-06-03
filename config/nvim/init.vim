" Disable Vi compatibility.
set nocompatible

call plug#begin('~/.config/nvim/plugged')

Plug 'itchyny/lightline.vim'
Plug 'powerline/powerline'
Plug 'vim-ruby/vim-ruby'
Plug 'thoughtbot/vim-rspec'
Plug 'tpope/vim-rails'
Plug 'tpope/vim-rake'
Plug 'tpope/vim-haml'
Plug 'tpope/vim-fugitive'
Plug 'tommcdo/vim-fubitive'
Plug 'tpope/vim-surround'
Plug 'tpope/vim-sensible'
Plug 'tpope/vim-markdown'
Plug 'tpope/vim-endwise'
Plug 'tpope/vim-dispatch'
Plug 'jremmen/vim-ripgrep'
Plug 'Shougo/deoplete.nvim', { 'do': ':UpdateRemotePlugins' }
Plug 'kchmck/vim-coffee-script'
Plug 'neomake/neomake'
Plug 'duggiefresh/vim-easydir'
Plug 'JamshedVesuna/vim-markdown-preview'
Plug '/usr/local/opt/fzf'
Plug 'stulzer/vim-vroom'
Plug 'craigemery/vim-autotag'

" Automatic formatting files
Plug 'sbdchd/neoformat'

Plug 'sheerun/vim-polyglot'
Plug 'slashmili/alchemist.vim'

" Javascript
Plug 'flowtype/vim-flow'

call plug#end()

" on opening the file, clear search-highlighting
autocmd BufReadCmd set nohlsearch

" Format js files
autocmd BufWritePre *.js Neoformat

" Without this, the next line copies a bunch of netrw settings like `let
" g:netrw_dirhistmax` to the system clipboard.
" I never use netrw, so disable its history.
let g:netrw_dirhistmax = 0

set encoding=utf-8
set mouse=a
set nu
set history=10000
set noswapfile    " http://robots.thoughtbot.com/post/18739402579/global-gitignore#comment-458413287
set ruler         " show cursor position all the time
set showcmd       " display incomplete commands
set incsearch     " do incremental searching
set modelines=2   " inspect top/bottom 2 lines for modeline
set scrolloff=1   " When scrolling, keep cursor in the middle
set shiftround    " When at 3 spaces and I hit >>, go to 4, not 5.
set number "Show line number
set wildignore=*.swp,*.bak,*.pyc,*.class
set nobackup
set noswapfile
set background=dark
set clipboard=unnamed
set ignorecase smartcase
set tabstop=2
set shiftwidth=2
set expandtab

" Set the title of the iterm tab
set title titlestring=%t

" highlight all occurrences when searching
set hlsearch

augroup myfiletypes
  " Clear old autocmds in group
  autocmd!
	" Include ! as a word character, so dw will delete all of e.g. gsub!,
	" and not leave the "!"
	au FileType ruby,eruby,yaml set iskeyword+=!,?
  " autoindent with two spaces, always expand tabs
  autocmd FileType ruby,eruby,yaml,coffee,js setlocal ai sw=2 sts=2 et
  autocmd FileType ruby,eruby,yaml,coffee,js setlocal path+=lib

	au BufNewFile,BufRead,BufWrite *.md,*.markdown,*.html syntax match Comment /\%^---\_.\{-}---$/
	autocmd VimResized * wincmd =
augroup END

" Big Yank to clipboard
nnoremap Y "*yiW

let mapleader = ","

au BufRead,BufNewFile Podfile set filetype=ruby
au BufRead,BufNewFile Berksfile set filetype=ruby
au BufRead,BufNewFile Berksfile set filetype=ruby
au BufRead,BufNewFile *.hamlc set filetype=haml
au BufRead,BufNewFile *.rake set filetype=ruby
au BufRead,BufNewFile *.ejs set filetype=html

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

" Elixir - Alchemist
let g:alchemist_tag_disable = 1

" Automatically removing all trailing whitespace
autocmd BufWritePre * :%s/\s\+$//e

"Abbreviations
ab pry require 'pry';binding.pry

" ruby
autocmd FileType ruby,eruby set omnifunc=rubycomplete#Complete
autocmd FileType ruby,eruby let g:rubycomplete_buffer_loading = 1
autocmd FileType ruby,eruby let g:rubycomplete_rails = 1
autocmd FileType ruby,eruby let g:rubycomplete_classes_in_global = 1

if executable('ag')
	let g:ackprg = 'ag --vimgrep'
endif

let g:deoplete#enable_at_startup = 1

" Calls neomake when saving file and opens up the list automatically
call neomake#configure#automake('w')
let g:neomake_open_list = 2

" vim-vroom configuration
let g:vroom_use_terminal = 1
let g:vroom_command_prefix="docker-compose run web"
map <leader>t :VroomRunNearestTest<cr>
map <leader>o :VroomRunTestFile<cr>

let g:rspec_command = "!clear && bin/rspec {spec}"
let g:rspec_runner = "os_x_iterm2"

" STATUSLINE
" always display status line
set laststatus=2
" Don't show `-- INSERT --` below the statusbar since it's in the statusbar
set noshowmode

let g:lightline = {}
let g:lightline.component = {}
let g:lightline.component_function = {}
let g:lightline.component_visible_condition = {}
let g:lightline.tabline = {}

let g:lightline.colorscheme = 'darcula'
let g:lightline.active = {}
let g:lightline.active.left = [
      \ ['mode', 'paste'],
      \ ['fugitive', 'readonly', 'myfilename', 'modified']
      \ ]
let g:lightline.component.fugitive = '%{exists("*fugitive#head")?fugitive#head():""}'
let g:lightline.component.readonly = '%{(&filetype!="help" && &readonly) ? "RO" : ""}'
let g:lightline.component_function.myfilename = 'LightLineFilename'
let g:lightline.component_visible_condition.readonly = '(&filetype!="help"&& &readonly)'
let g:lightline.component_visible_condition.fugitive = '(exists("*fugitive#head") && ""!=fugitive#head())'
let g:lightline.tabline.right = [] " Disable the 'X' on the far right

function! LightLineFilename()
  let git_root = fnamemodify(fugitive#extract_git_dir(expand("%:p")), ":h")

  if expand("%:t") == ""
    return "[No Name]"
  elseif git_root != "" && git_root != "."
    return substitute(expand("%:p"), git_root . "/", "", "")
  else
    return expand("%:p")
  endif
endfunction

" vim-plug loads all the filetype, syntax and colorscheme files, so turn them on
" _after_ loading plugins.
syntax enable
filetype plugin indent on

let vim_markdown_preview_github=1

" Vim Notes
let g:notes_directories = ['~/notes/personal', '~/notes/work']
let g:notes_suffix = '.md'

" FZF mapings
nmap <C-p> :FZF<CR>
map <leader>cv :FZF app/views<cr>
map <leader>ct :FZF app/controllers<cr>
map <leader>cm :FZF app/models<cr>
map <leader>cp :FZF app/presenters<cr>
map <leader>cs :FZF spec<cr>
map <leader>cl :FZF lib<cr>
