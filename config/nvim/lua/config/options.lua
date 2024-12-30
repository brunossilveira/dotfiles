vim.cmd("let g:netrw_liststyle = 3")

local opt = vim.opt

opt.relativenumber = true
opt.number = true

-- tabs & indentation
opt.tabstop = 2 -- 2 spaces for tabs
opt.shiftwidth = 2 -- 2 spaces for indent width
opt.expandtab = true -- expand tab to spaces
opt.autoindent = true -- copy indent from current line when starting new one

opt.wrap = false

-- search settings
opt.ignorecase = true -- ignore case when searching
opt.smartcase = true -- when searching with mixed case, assumes case-sensitive

opt.cursorline = true


-- styling
opt.termguicolors = true
opt.background = 'dark'
opt.signcolumn = 'yes' -- show sign column so that text doesn't shift

-- backspace 
opt.backspace = 'indent,eol,start' -- allow backspace on indent, end of line or insert mode start position--  

-- clipboard
opt.clipboard:append("unnamedplus")

-- split windows
opt.splitright = true
opt.splitbelow = true

-- turn swapfile off
opt.swapfile = false
