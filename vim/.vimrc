"------------------------------------------------------------------------------
" SOURCE VIM CONFIGS 
"------------------------------------------------------------------------------

" dougblack.io/words/a-good-vimrc.html
" realpython.com/blog/python/vim-and-python-a-match-made-in-heaven/
" witkowskibartosz.com/blog/gitgutter-vim-plugin.html
" github.com/amix/vimrc/tree/master/vimrcs
" vimcasts.org/episodes/spell-checking/
" nvie.com/posts/how-i-boosted-my-vim/
" medium.com/usevim/vim-101-set-hidden-f78800142855
"
"
"------------------------------------------------------------------------------
" MISC 
"------------------------------------------------------------------------------

set nocompatible "be iMproverd, required
let mapleader=',' "leader is comma
" jk is escape
inoremap jk <ESC>
set nostartofline               " Make j/k respect the columns

" <leader>k is move right one space
inoremap <leader>k <right>
set clipboard=unnamedplus "to use operating system clipboard

" ignore compiled files
set wildignore=*.o,*~,*.pyc,*.so,*.out,*.log,*.aux,*.bak,*.swp,*.class
if has("win16") || has("win32")
    set wildignore+=.git\*,.hg\*,.svn\*
else
    set wildignore+=*/.git/*,*/.hg/*,*/.svn/*,*/.DS_Store
endif

set history=1000  " set how many lines of history vim has to remember
set autoread " set the file to autoread when a file is changed from outside
set encoding=utf8 
set esckeys                     " Allow cursor keys in insert mode.
set nowrap  "don't wrap lines
set title                " change the terminal's title
set visualbell           " don't beep
set noerrorbells         " don't beep
set spelllang=en " 'en_gb' sets region to British English. use 'en' for all regions

"------------------------------------------------------------------------------
" COLORS 
"------------------------------------------------------------------------------

if $COLORTERM == 'gnome-terminal'
  set term=screen-256color "set teminal color to support 256 colors
endif

try
  " colorscheme molokai
  colorscheme spacegray
catch
  colorscheme desert
endtry

set background=dark
syntax enable " enable syntax processing

" colorscheme spcegray
let g:spacegray_low_contrast = 1
let g:spacegray_use_italics = 1
let g:spacegray_underline_search = 1

"------------------------------------------------------------------------------
" SPACES AND TABS 
"------------------------------------------------------------------------------

set autoindent
set smartindent
set expandtab " tabs are spaces
" set tabstop=2 " number of visual spaces per TAB
set shiftwidth=2
set softtabstop=2 " number of spaces in TAB when editing


"------------------------------------------------------------------------------
" UI CONFIG 
"------------------------------------------------------------------------------

set number " show line numbers
set showcmd " shows last entered command in bottom right bar, not working
set cursorline " highlight current line
set ruler

" toggle line numbers
nnoremap <leader>tn :set number!<CR>
nnoremap <leader>trn :set relativenumber!<CR>

" filetype on "required
filetype off "required
filetype plugin indent on    " required
"filetype indent on " load filetype-specific indent files ~/.vim/indent/python.vim

set splitright
set splitbelow

"matching pair of braces
inoremap {      {}<Left>
inoremap {<CR>  {<CR>}<Esc>O
inoremap {{     {
inoremap {}     {}

"matching pair of square brackets
inoremap [      []<Left>
inoremap [<CR>  [<CR>]<Esc>O
inoremap [[     [
inoremap []     []

"handling paranthesis
inoremap (      ()<Left>
inoremap (<CR>  (<CR>)<Esc>O
inoremap ((     (
inoremap ()     ()

" "handling angular brackets
" inoremap <      <><Left>
" inoremap <<CR>  <<CR>><Esc>O
" inoremap <<     <
" inoremap <>     <>

set wildmenu " visual autocomplete for command menu
set lazyredraw " redraw only when needed
set showmatch " highlight matching [{()}]


"------------------------------------------------------------------------------
" SEARCHING 
"------------------------------------------------------------------------------

" Use case insensitive search, except when using capital letters
set ignorecase
set smartcase
set incsearch " incremental search. search as chars are enetered
set hlsearch " highlight matches
set gdefault                " RegExp global by default
set magic                   " Enable extended regexes.

" turn off search highlight
nnoremap <leader><space> :nohlsearch<CR>

" Visual mode pressing * or # searches for the current selection
" visual selection is custom function. [see the section]
vnoremap <silent> * :<C-u>call VisualSelection('', '')<CR>/<C-R>=@/<CR><CR>
vnoremap <silent> # :<C-u>call VisualSelection('', '')<CR>?<C-R>=@/<CR><CR>

" Folding -----------------------------------------------------
set foldenable " enable folding
set foldlevelstart=10 " open most folds by default
set foldnestmax=10 " max 10 nested folds
" space open/closes folds in current block
nnoremap <space> za
" fold based on syntax. other values are: indent, marker, manual, expr, diff, syntax
set foldmethod=marker " no plugin for syntax yet.


"------------------------------------------------------------------------------
" MOVEMENTS 
"------------------------------------------------------------------------------

" move vertically by visual line
nnoremap j gj
nnoremap k gk

" move to end/beginning of line(normal mode)
nnoremap E $
nnoremap B ^

" move to end/beginning of line(visual mode)
vnoremap E $
vnoremap B ^

" $/^ doesn't do anything(normal mode)
nnoremap $ <nop>
nnoremap ^ <nop>

" $/^ doesn't do anything(visual mode)
vnoremap $ <nop>
vnoremap ^ <nop>

"split navigations
nnoremap <C-J> <C-W><C-J>
nnoremap <C-K> <C-W><C-K>
nnoremap <C-L> <C-W><C-L>
nnoremap <C-H> <C-W><C-H>


"------------------------------------------------------------------------------
" LEADER SHORTCUTS 
"------------------------------------------------------------------------------

" edit/load vimrc/bashrc
nnoremap <leader>ev :vsp $MYVIMRC<CR>
nnoremap <leader>eb :vsp ~/.bashrc<CR>
nnoremap <leader>sv :source $MYVIMRC<CR>

" save session. 
" nnoremap <leader>s :mksession<CR>

" Remove the Windows ^M - when the encodings gets messed up
noremap <Leader>m mmHmt:%s/<C-V><cr>//ge<cr>'tzt'm

" stage current file in git
nnoremap <leader>ga :!git add %<CR>

"spell check toggle
nmap <silent> <leader>s :set spell!<cr>

"------------------------------------------------------------------------------
" PLUGINS 
"------------------------------------------------------------------------------

" set the runtime path to include Vundle and initialize
set rtp+=~/.vim/bundle/Vundle.vim
call vundle#begin()

Plugin 'gmarik/Vundle.vim'
" Plugin 'ying17zi/vim-live-latex-preview'
" Plugin 'LaTeX-Box-Team/LaTeX-Box'
Plugin 'tomasr/molokai'
Plugin 'ajh17/Spacegray.vim'
" gundo
" ctrlP
" ag
" ycm
" ultisnips
" fugitive
Plugin 'airblade/vim-gitgutter'
" markdown
" indentmarkers
" syntastic
" vinegar
" airline
" closetag : plugin for autoclose html
Plugin 'alvan/vim-closetag'

call vundle#end()            " required


" gitgutter configs

set updatetime=1000 "wait how much time to detect file update
let g:gitgutter_max_signs = 500 "threshold upto which gitgutter shows sign
let g:gitgutter_highlight_lines = 1

nmap gn <Plug>GitGutterNextHunk
nmap gp <Plug>GitGutterPrevHunk
nmap <leader>hs <Plug>GitGutterStageHunk
nmap <leader>hu <Plug>GitGutterUndoHunk
nmap <leader>hp <Plug>GitGutterPreviewHunk            

nnoremap <leader>ggt <esc>:GitGutterToggle<cr>

if exists('&signcolumn')  " Vim 7.4.2201
  set signcolumn=yes
else
  let g:gitgutter_sign_column_always = 1
endif


" molokai theme config
let g:molokai_original=1


" vim-closetag
" filenames like *.xml, *.html, *.xhtml, ...
" These are the file extensions where this plugin is enabled.
"
let g:closetag_filenames = '*.html,*.xhtml,*.phtml'

" filenames like *.xml, *.xhtml, ...
" This will make the list of non-closing tags self-closing in the specified files.
"
let g:closetag_xhtml_filenames = '*.xhtml,*.jsx'

" integer value [0|1]
" This will make the list of non-closing tags case-sensitive (e.g. `<Link>` will be closed while `<link>` won't.)
"
let g:closetag_emptyTags_caseSensitive = 1

" Shortcut for closing tags, default is '>'
"
let g:closetag_shortcut = '>'

" Add > at current position without closing the current tag, default is ''
"
let g:closetag_close_shortcut = '<leader>>'
"------------------------------------------------------------------------------
" AUTO COMMANDS  
"------------------------------------------------------------------------------

au FileType tex nnoremap <buffer> <leader>t :!pdflatex % <CR>
au FileType tex nnoremap <buffer> <leader>x :!xelatex % <CR>


"------------------------------------------------------------------------------
" CUSTOM FUNCTIONS
"------------------------------------------------------------------------------

function! VisualSelection(direction, extra_filter) range
    let l:saved_reg = @"
    execute "normal! vgvy"

    let l:pattern = escape(@", "\\/.*'$^~[]")
    let l:pattern = substitute(l:pattern, "\n$", "", "")

    if a:direction == 'gv'
        call CmdLine("Ack '" . l:pattern . "' " )
    elseif a:direction == 'replace'
        call CmdLine("%s" . '/'. l:pattern . '/')
    endif

    let @/ = l:pattern
    let @" = l:saved_reg
endfunction

"------------------------------------------------------------------------------
" END
"------------------------------------------------------------------------------
