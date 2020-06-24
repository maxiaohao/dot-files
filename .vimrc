call plug#begin('~/.vim/plugged')

"Plug 'bling/vim-airline'
Plug 'tpope/vim-fugitive'
Plug 'airblade/vim-gitgutter'
Plug 'tpope/vim-surround'
Plug 'scrooloose/nerdtree'
"Plug 'fatih/vim-go'
Plug 'godlygeek/tabular'
Plug 'ervandew/supertab'
Plug 'takac/vim-hardtime'
"Plug '/usr/sbin/fzf'
Plug 'junegunn/fzf'
Plug 'dhruvasagar/vim-table-mode'

call plug#end()

set number relativenumber
set ignorecase
set nobackup
set hlsearch
set tabstop=2
set shiftwidth=2
set expandtab
"set autoindent
set smartindent
"set cursorline
set hidden                   " allow swith without saving buffer
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

syntax on

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


"NerdTree use <F5>
"let NERDTreeWinPos='right'
"let NERDTreeWinSize=31
"let NERDTreeChDirMode=1
map <F5> :NERDTreeToggle<CR>

"trim 3+ blank lines into at most 2 blank lines
function! TrimBlankLines()
    %s/\(\n\n\)\n\+/\r\r\r/e
endfunction

"on writing specified type of files, automatically trim any trailing white spaces
autocmd BufWritePre *.java,*js,*.css,*.html :%s/\s\+$//e

"auto complete braces
"inoremap ( ()<LEFT>
"inoremap [ []<LEFT>
"inoremap < <><ESC>i
"inoremap { {<CR>}<ESC>O<Tab>

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

let g:airline_powerline_fonts = 1

let g:hardtime_default_on = 0
let g:hardtime_timeout = 200
let g:hardtime_maxcount = 10

" allow saving file in new dir
augroup BWCCreateDir
    autocmd!
    autocmd BufWritePre * if expand("<afile>")!~#'^\w\+:/' && !isdirectory(expand("%:h")) | execute "silent! !mkdir -p ".shellescape(expand('%:h'), 1) | redraw! | endif
augroup END
