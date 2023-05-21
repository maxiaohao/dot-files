call plug#begin('~/.vim/plugged')

Plug 'airblade/vim-gitgutter'
Plug 'bling/vim-airline'
Plug 'dhruvasagar/vim-table-mode'
Plug 'easymotion/vim-easymotion'
Plug 'ervandew/supertab'
Plug 'godlygeek/tabular'
Plug 'jiangmiao/auto-pairs'
Plug 'junegunn/fzf', { 'do': { -> fzf#install() } }
Plug 'junegunn/fzf.vim'
Plug 'neoclide/coc.nvim', {'branch': 'release'}
Plug 'scrooloose/nerdtree'
Plug 'Xuyuanp/nerdtree-git-plugin', { 'on': 'NERDTreeToggle' } "NERDTree plugin which shows git status flags.
Plug 'takac/vim-hardtime'
Plug 'terryma/vim-expand-region'
Plug 'tpope/vim-fugitive'
Plug 'tpope/vim-surround'
Plug 'pappasam/coc-jedi', { 'do': 'yarn install --frozen-lockfile && yarn build', 'branch': 'main' }
Plug 'simeji/winresizer'
Plug 'tpope/vim-commentary' "Quick (un)comment line(s), shortcut key `\\`.
"Plug 'mg979/vim-visual-multi' "Multiple cursors plugin for vim/neovim.

Plug 'pangloss/vim-javascript'
Plug 'vim-python/python-syntax'
Plug 'fatih/vim-go'
"Plug 'elzr/vim-json'
Plug 'cespare/vim-toml'
Plug 'stephpy/vim-yaml'

call plug#end()

set number relativenumber
set ignorecase
set nobackup
set hlsearch
set tabstop=2
set shiftwidth=2
set expandtab
set autoindent
set smartindent
"set cursorline
set hidden "allow swith without saving buffer
set autochdir
set noerrorbells
set novisualbell
set nofoldenable
set mouse=
set lazyredraw

set encoding=utf-8
set termencoding=utf-8
set fileencoding=utf-8
set fileencodings=ucs-bom,utf-8,chinese,cp936

set backspace=indent,eol,start

set scrolloff=3
set listchars+=nbsp:.

syntax on
set synmaxcol=200 "Don't perform highlight on lines that are longer than 200 chars.
syntax sync minlines=1000

colorscheme desert

function! SwitchToNextBuffer(incr)
    let help_buffer = (&filetype == 'help')
    let current = bufnr("%")
    let last = bufnr("$")
    let new = current + a:incr
    while 1
        if new != 0 && bufexists(new) && ((getbufvar(new, "&filetype") == 'help') == help_buffer)
            execute ":buffer ".new
            break
        else
            let new = new + a:incr
            if new < 1
                let new = last
            elseif new > last
                let new = 1
            endif
            if new == current
                break
            endif
        endif
    endwhile
endfunction

map <silent> <F3> :call SwitchToNextBuffer(-1)<CR>
map <silent> <F4> :call SwitchToNextBuffer(1)<CR>


"let NERDTreeWinPos='right'
"let NERDTreeWinSize=31
"let NERDTreeChDirMode=1
let NERDTreeIgnore=['\.pyc$', '\.o$', '\~$', '__pycache__', '\.mypy_cache', '\.DS_Store', '^\.git$', '\.o$', '\.so$', '\.egg$', "\.pytest_cache", "\.swp$", "\.swo$", "\.swn$"]
"NerdTree toggle: <F5>
"map <F5> :NERDTreeToggle<CR>
"NerdTree toggle: ':NT'
:command NT :NERDTreeToggle

"trim 3+ blank lines into at most 2 blank lines
function! TrimBlankLines()
    %s/\(\n\n\)\n\+/\r\r\r/e
endfunction

"on writing specified type of files, automatically trim any trailing white spaces
autocmd BufWritePre *.java,*js,*.css,*.html :%s/\s\+$//e

"auto complete braces
""""""inoremap ( ()<LEFT>
""""""inoremap [ []<LEFT>
""""""""inoremap < <><ESC>i
""""""inoremap { {<CR>}<ESC>O<Tab>
""""""inoremap " ""<LEFT>
""""""inoremap ' ''<LEFT>
"inoremap ( ()<LEFT>
"inoremap [ []<LEFT>
"inoremap { {}<LEFT>
"inoremap {<CR> {<CR>}<ESC>O
"inoremap {;<CR> {<CR>};<ESC>O
"inoremap kk <Esc>

"Syntastic conf
"let g:syntastic_error_symbol='✗'x
"let g:syntastic_warning_symbol='⚠'
"let g:syntastic_error_symbol='>'
"let g:syntastic_warning_symbol='>'
let g:syntastic_auto_loc_list=1
let g:syntastic_stl_format = '[%E{Err: %fe #%e}%B{, }%W{Warn: %fw #%w}]'
let g:syntastic_check_on_open=1

"JSHint conf
let g:syntastic_javascript_syntax_checker="jshint"
let g:syntastic_javascript_jshint_conf="~/.jshintrc"

" trim trailing space
autocmd BufWritePre * :%s/\s\+$//e

set colorcolumn=101
highlight ColorColumn ctermbg=238

highlight LineNr ctermfg=240

hi Search cterm=NONE ctermfg=grey ctermbg=4

let g:airline_powerline_fonts = 0

let g:hardtime_default_on = 0
let g:hardtime_timeout = 200
let g:hardtime_maxcount = 10

" allow saving file in new dir
augroup BWCCreateDir
    autocmd!
    autocmd BufWritePre * if expand("<afile>")!~#'^\w\+:/' && !isdirectory(expand("%:h")) | execute "silent! !mkdir -p ".shellescape(expand('%:h'), 1) | redraw! | endif
augroup END

" Fix auto-indentation for YAML files
augroup yaml_fix
    autocmd!
    autocmd FileType yaml setlocal ts=2 sts=2 sw=2 expandtab indentkeys-=0# indentkeys-=<:>
augroup END

" go-vim
let g:go_test_timeout = '3s'
"let g:go_term_enabled = 1

" coc
hi! CocErrorSign guifg=#550000
" hi! CocInfoSign guibg=#353b45
" hi! CocWarningSign guifg=#d1cd66
let g:coc_node_path = '~/.nix-profile/bin/node'

" win resizer
let g:winresizer_start_key = '<C-Q>'

"Plugin :: tpope/vim-commentary --------------------------------------- {{{
"Type `\\` to toggle comments for current line or selected blocks.
xmap <Leader><Leader>  <Plug>Commentary
nmap <Leader><Leader>  <Plug>Commentary
omap <Leader><Leader>  <Plug>Commentary
nmap <Leader><Leader>  <Plug>CommentaryLine
" End Plugin :: tpope/vim-commentary ---------------------------------- }}}
