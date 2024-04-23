call plug#begin('~/.vim/plugged')

Plug 'airblade/vim-gitgutter'
"Plug 'bling/vim-airline'
Plug 'dhruvasagar/vim-table-mode'
Plug 'easymotion/vim-easymotion'
"Plug 'ervandew/supertab'
Plug 'godlygeek/tabular'
Plug 'jiangmiao/auto-pairs'
Plug 'junegunn/fzf', { 'do': { -> fzf#install() } }
Plug 'junegunn/fzf.vim'
Plug 'neoclide/coc.nvim', {'branch': 'release'}
Plug 'preservim/nerdtree'
Plug 'ryanoasis/vim-devicons'
Plug 'takac/vim-hardtime'
Plug 'terryma/vim-expand-region'
Plug 'tpope/vim-fugitive'
Plug 'tpope/vim-surround'
Plug 'simeji/winresizer'
Plug 'tpope/vim-commentary' "Quick (un)comment line(s), shortcut key `\\`.
"Plug 'mg979/vim-visual-multi' "Multiple cursors plugin for vim/neovim.

Plug 'bling/vim-bufferline'
"Plug 'ap/vim-buftabline'

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
set cursorline
set hidden "allow switching without saving buffer
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
set synmaxcol=200 "Don't perform highlight on lines that are longer than 200 chars.
set colorcolumn=101
set showtabline=1
syntax on
syntax sync minlines=1000




""""""""""""""""""""""""""
""""" color - BEGIN """"""
""""""""""""""""""""""""""
colorscheme desert
highlight ColorColumn ctermbg=237
highlight LineNr ctermfg=240
highlight Search cterm=NONE ctermfg=grey ctermbg=4
highlight CursorLine cterm=none term=none ctermbg=235
autocmd WinEnter * setlocal cursorline
autocmd WinLeave * setlocal nocursorline
""""""""""""""""""""""""""
""""" color - BEGIN """"""
""""""""""""""""""""""""""




"""""""""""""""""""""""""""""
""""" NERDTree - BEGIN """"""
"""""""""""""""""""""""""""""
"let NERDTreeWinPos='right'
"let NERDTreeWinSize=31
"let NERDTreeChDirMode=1
let NERDTreeIgnore=['\.pyc$', '\.o$', '\~$', '__pycache__', '\.mypy_cache', '\.DS_Store', '^\.git$', '\.o$', '\.so$', '\.egg$', "\.pytest_cache", "\.swp$", "\.swo$", "\.swn$"]
map <C-T> :NERDTreeToggle<CR>
map <C-L> :NERDTreeFind<CR>
:command NT :NERDTreeToggle
"""""""""""""""""""""""""""
""""" NERDTree - END """"""
"""""""""""""""""""""""""""




""""""""""""""""""""""""
""""" coc - BEGIN """"""
""""""""""""""""""""""""
"let g:coc_node_path = '/Users/kevin.ma/dev/tool/IN_PATH/node'

set nobackup
set nowritebackup
set updatetime=300
set signcolumn=yes
" To suppress the "ATTENTION" message when external commands are executed
set shortmess+=c

" <TAB> OR <ENTER> for selecting an item in auto-completion
inoremap <silent><expr> <TAB> coc#pum#visible() ? coc#pum#confirm() : "\<C-g>u\<TAB>"
inoremap <silent><expr> <ENTER> coc#pum#visible() ? coc#pum#confirm() : "\<C-g>u\<ENTER>"

" Use `[g` and `]g` to navigate diagnostics
" Use `:CocDiagnostics` to get all diagnostics of current buffer in location list.
nmap <silent> [g <Plug>(coc-diagnostic-prev)
nmap <silent> ]g <Plug>(coc-diagnostic-next)

" GoTo code navigation.
nmap <silent> gd <Plug>(coc-definition)
nmap <silent> gy <Plug>(coc-type-definition)
nmap <silent> gi <Plug>(coc-implementation)
nmap <silent> gr <Plug>(coc-references)

" Use gh to show documentation in preview window.
nnoremap <silent> gh :call <SID>show_documentation()<CR>

function! s:show_documentation()
  if (index(['vim','help'], &filetype) >= 0)
    execute 'h '.expand('<cword>')
  elseif (coc#rpc#ready())
    call CocActionAsync('doHover')
  else
    execute '!' . &keywordprg . " " . expand('<cword>')
  endif
endfunction

" Symbol renaming.
nmap <leader>rn <Plug>(coc-rename)
" Remap keys for applying codeAction to the current buffer.
nmap <leader>ac  <Plug>(coc-codeaction)
" Apply AutoFix to problem on the current line.
nmap <leader>qf  <Plug>(coc-fix-current)

highlight CocFloating ctermbg=24
highlight CocMenuSel ctermbg=166

"""""""""""""""""""""
""""" coc - END """""
"""""""""""""""""""""





""""""""""""""""""""""""""""""
""""" other keys - BEGIN """""
""""""""""""""""""""""""""""""
nmap <C-n> :bn<CR>
nmap <C-p> :bp<CR>

" window resizer
let g:winresizer_start_key = '<C-Q>'

" toggle comment/uncomment
noremap g/ :Commentary<CR>

" gq for :bd
noremap gq :bd<CR>

" Ctrl+Shift+t to run :GoTest
nnoremap <C-S-t> :GoTest<CR>
""""""""""""""""""""""""""""
""""" other keys - END """""
""""""""""""""""""""""""""""




"""""""""""""""""""""""""
""""" misc - BEGIN """"""
"""""""""""""""""""""""""
" trim trailing spaces
autocmd BufWritePre * :%s/\s\+$//e

" trim 3+ blank lines into at most 2 blank lines
function! TrimBlankLines()
    %s/\(\n\n\)\n\+/\r\r\r/e
endfunction

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

" bufferline highlight style
let g:bufferline_active_buffer_left = ' [ '
let g:bufferline_active_buffer_right = '] '

"let g:airline_powerline_fonts = 0

let g:hardtime_default_on = 0
let g:hardtime_timeout = 200
let g:hardtime_maxcount = 10

" go-vim
let g:go_test_timeout = '3s'
"let g:go_term_enabled = 1

" for tpope/vim-commentary
filetype plugin indent on

" only auto pair {} for jiangmiao/auto-pairs
let g:AutoPairs = {'{':'}'}

" shortcut gb to remove blank lines in the selected lines
vnoremap gb :<C-u>'<,'>g/^$/d<CR>

"""""""""""""""""""""""
""""" misc - END """"""
"""""""""""""""""""""""

