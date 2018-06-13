"------------------------------------------------------------
" CATEGORIES
"------------------------------------------------------------

" PLUGIN MANAGER
" MISC 
" COLORS 
" SPACES AND TABS 
" UI CONFIG 
" SEARCHING 
" MOVEMENTS 
" LEADER SHORTCUTS 
" PLUGIN SETTINGS
" AUTO COMMANDS  
" CUSTOM FUNCTIONS
" SOURCE VIM CONFIGS 

"------------------------------------------------------------
" PLUGIN MANAGER {{{
"------------------------------------------------------------

" download vim-plug and install plugins if vim started without plug.
if empty(glob('~/.vim/autoload/plug.vim'))
  silent !curl -fLo ~/.vim/autoload/plug.vim --create-dirs
        \ https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
  autocmd VimEnter * PlugInstall | source $MYVIMRC
endif

" plug plugin setup.
call plug#begin('~/.vim/plugged')

" Automatically install missing plugins on startup. [commented to improve startup
if !empty(filter(copy(g:plugs), '!isdirectory(v:val.dir)'))
  autocmd VimEnter * PlugInstall | q
endif

Plug 'tomasr/molokai'
Plug 'ajh17/Spacegray.vim'
Plug 'morhetz/gruvbox'          " currently in use

Plug 'xolox/vim-notes'| Plug 'xolox/vim-misc' 

Plug 'tpope/vim-fugitive'       " to handle git commands
Plug 'airblade/vim-gitgutter'   " to see git diff

Plug 'alvan/vim-closetag'       " to close markup lang tags

Plug 'mileszs/ack.vim'          " ag.vim is deprecated.
Plug 'sjl/gundo.vim'            " to see vim history-tree
" {{{ command-t when ruby support available else ctrlp
Plug 'wincent/command-t', has('ruby') ? {
    \ 'do': 'cd ruby/command-t/ext/command-t && ruby extconf.rb && make'
    \ }:{ 'on': [] }
" install 'the_silver_searcher for speeding up ack and ctrlp.
" github.com/ggreer/the_silver_searcher
Plug 'ctrlpvim/ctrlp.vim', has('ruby')?{'on':[]}:{}
" }}}
Plug 'scrooloose/vim-slumlord'
Plug 'aklt/plantuml-syntax'

" considerable plugins-not tried yet
" fzf (alternative of command-t)
" vimwiki (alternative of vim-notes)
" Plug 'ying17zi/vim-live-latex-preview'
" Plug 'LaTeX-Box-Team/LaTeX-Box'
" grepg
" vim surround
" ycm
" syntastic (ALE is an alternative: async)
" ultisnips
" markdown
" indentmarkers
" vinegar
" airline (lighther than powerline: a custome statusline can be used: would be even lighter)

call plug#end() 

" PS - a deeper look needed for fugitive, gundo, command-t, notes, ack.
" }}}

"------------------------------------------------------------
" MISC {{{
"------------------------------------------------------------

" set nocompatible          "commented: r/vim/wiki/vimrctips
let mapleader=','           "leader is comma
set nostartofline           " Make j/k respect the columns
set clipboard=unnamedplus   "to use operating system clipboard
set history=1000            " set how many lines of history vim has to remember
set autoread                " set the file to autoread when a file is changed from outside
set encoding=utf8           " set vim encoding to utf-8
set esckeys                 " Allow cursor keys in insert mode.
set title                   " change the terminal's title
set spelllang=en            " 'en_gb' sets region to British English. use 'en' for all regions
set noswapfile              " stops vim from creating a .swp file
" set nobackup              " " gives no error when same file being edited by multiple vim sessions
set textwidth=0             " no automatic linefeeds in insert mode
set wrap                    " word wrap the text(normal/visual)
set visualbell              " don't beep
set noerrorbells            " don't beep
syntax enable               " enable syntax processing
" clearing the t_vb variable deactivates flashing
set t_vb=
" jk is escape
inoremap jk <ESC>

" ignore compiled files
set wildignore=*.o,*~,*.pyc,*.so,*.out,*.log,*.aux,*.bak,*.swp,*.class
if has("win16") || has("win32")
    set wildignore+=.git\*,.hg\*,.svn\*
else
    set wildignore+=*/.git/*,*/.hg/*,*/.svn/*,*/.DS_Store
endif

"insert datetime in the format specified on <F9>
nnoremap <F9> "=strftime("%Y-%m-%d_%a")<CR>P
inoremap <F9> <C-R>=strftime("%Y-%m-%d_%a")<CR>

" }}}

"------------------------------------------------------------
" COLORS    {{{
"------------------------------------------------------------

set background=dark

" :call ShowColorSchemeName() to show the current colorscheme that vim is using[custom fn]
if $COLORTERM == 'gnome-terminal'
  set term=screen-256color "set teminal color to support 256 colors
endif

try
  "colorscheme molokai
  "colorscheme spacegray
  colorscheme gruvbox
catch
  colorscheme desert
endtry


" molokai theme - plugin config
" let g:molokai_original=1


" spacegray theme - plugin config
" let g:spacegray_low_contrast = 1
" let g:spacegray_use_italics = 1
" let g:spacegray_underline_search = 1

" gruvbox - plugin config
let g:gruvbox_contrast_dark='soft'

" }}}

"------------------------------------------------------------
" SPACES AND TABS  {{{
"------------------------------------------------------------

set autoindent
set cindent       " better alternative to smartindent
set expandtab     " tabs are spaces
" set tabstop=2   " commented: r/vim/wiki/tabstop
set shiftwidth=2
set softtabstop=2 " number of spaces in TAB when editing


" }}}

"------------------------------------------------------------
" UI CONFIG  {{{
"------------------------------------------------------------

set number          " show line numbers
set relativenumber  " show relative line number
set showcmd         " shows last entered command in bottom right bar, not working
set cursorline      " highlight current line
set scrolloff=5     " minimum line offset to present on screen while scrolling.

" removed the below filetype plugin block as vim-plug handles it internally
" filetype on "required
" filetype off "required
" filetype plugin indent on    " required


"filetype indent on " load filetype-specific indent files ~/.vim/indent/python.vim

set splitright
set splitbelow

"matching pair of braces
inoremap {      {}<Left>
inoremap {<CR>  {<CR>}<Esc>O
" inoremap {{     {
inoremap {}     {}

"matching pair of square brackets
inoremap [      []<Left>
inoremap [<CR>  [<CR>]<Esc>O
" inoremap [[     [
inoremap []     []

"handling paranthesis
inoremap (      ()<Left>
inoremap (<CR>  (<CR>)<Esc>O
" inoremap ((     (
inoremap ()     ()

" "handling angular brackets
" inoremap <      <><Left>
" inoremap <<CR>  <<CR>><Esc>O
" inoremap <<     <
" inoremap <>     <>

set wildmode=longest,list,full
set wildmenu    " visual autocomplete for command menu
set lazyredraw  " redraw only when needed
set showmatch   " highlight matching [{()}]

" vim statusline {{{
function! GitBranch()
  return system("git rev-parse --abbrev-ref HEAD 2>/dev/null | tr -d '\n'")
endfunction

function! StatuslineGit()
  let l:branchname = GitBranch()
  return strlen(l:branchname) > 0?'  '.l:branchname.' ':''
endfunction



let g:currentmode={
    \ 'n'  : 'N ',
    \ 'no' : 'N·Operator Pending ',
    \ 'v'  : 'V ',
    \ 'V'  : 'V·Line ',
    \ '^V' : 'V·Block ',
    \ 's'  : 'Select ',
    \ 'S'  : 'S·Line ',
    \ '^S' : 'S·Block ',
    \ 'i'  : 'I ',
    \ 'R'  : 'R ',
    \ 'Rv' : 'V·Replace ',
    \ 'c'  : 'Command ',
    \ 'cv' : 'Vim Ex ',
    \ 'ce' : 'Ex ',
    \ 'r'  : 'Prompt ',
    \ 'rm' : 'More ',
    \ 'r?' : 'Confirm ',
    \ '!'  : 'Shell ',
    \ 't'  : 'Terminal '
    \}

" Automatically change the statusline color depending on mode
function! ChangeStatuslineColor()
  if (mode() =~# '\v(n|no)')
    exe 'hi! StatusLine ctermfg=009'
  elseif (mode() =~# '\v(v|V)' || g:currentmode[mode()] ==# 'V·Block' || get(g:currentmode, mode(), '') ==# 't')
    exe 'hi! StatusLine ctermfg=009'
  elseif (mode() ==# 'i')
    exe 'hi! StatusLine ctermfg=009'
  else
    exe 'hi! StatusLine ctermfg=009'
  endif

  return ''
endfunction

set laststatus=2
set statusline=
set statusline+=%#PmenuSel#           " set blue color
set statusline+=%{StatuslineGit()}    " get git branch name
set statusline+=%#LineNr#             " break blue color after br name
set statusline+=\ %f                  " file name
set statusline+=\%m                   " modified status/flag
set statusline+=%=
set statusline+=%#CursorColumn#
set statusline+=\%y                   " file type
set statusline+=\[%{&fileencoding?&fileencoding:&encoding}]     " file encoding
set statusline+=\[%{&fileformat}\]    " file format[unix/dos]
set statusline+=\ %p%%                " file position percentage
set statusline+=\ %l:%c               " line:col
" set statusline+=\ %{strftime('%R', getftime(expand('%')))}      " lst saved time
set statusline+=%0*\ %{toupper(g:currentmode[mode()])}   " Current mode
set statusline+=\ 
" }}}

"------------------------------------------------------------
" SEARCHING  {{{
"------------------------------------------------------------

set ignorecase    " use case insensitive search
set smartcase     " except when using capital letters
set incsearch     " incremental search. search as chars are enetered
set hlsearch      " highlight matches
set gdefault      " RegExp global by default
set magic         " Enable extended regexes.

" turn off search highlight
nnoremap <leader><space> :nohlsearch<CR>

" Visual mode pressing * or # searches for the current selection
" visual selection is custom function. [see the section]
vnoremap <silent> * :<C-u>call VisualSelection('', '')<CR>/<C-R>=@/<CR><CR>
vnoremap <silent> # :<C-u>call VisualSelection('', '')<CR>?<C-R>=@/<CR><CR>

" highlight last inserted text
nnoremap gV `[v`]

" Folding {{{
set foldenable          " enable folding
set foldlevelstart=10   " open most folds by default
set foldnestmax=10      " max 10 nested folds
" space open/closes folds in current block
nnoremap <space> za
" foldmethod values: indent, marker, manual, expr, diff, syntax
set foldmethod=marker   " no plugin for syntax yet.

" }}}

" }}}

"------------------------------------------------------------
" MOVEMENTS  {{{
"------------------------------------------------------------

" move vertically by visual line(normal/visual mode)
noremap j gj
noremap k gk

" move to end/beginning of line(normal/visual  mode)
noremap E $
noremap B ^

" $/^ doesn't do anything(normal/visual mode)
noremap $ <nop>
noremap ^ <nop>

"split navigations
nnoremap <C-J> <C-W><C-J>
nnoremap <C-K> <C-W><C-K>
nnoremap <C-L> <C-W><C-L>
nnoremap <C-H> <C-W><C-H>


" }}}

"------------------------------------------------------------
" LEADER SHORTCUTS  {{{
"------------------------------------------------------------

" toggle line numbers
nnoremap <leader>tn :set number!<CR>
nnoremap <leader>trn :set relativenumber!<CR>

" <leader>k is move right one space
inoremap <leader>k <right>

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
nnoremap <silent> <leader>s :set spell!<cr>


" }}}

"------------------------------------------------------------
" PLUGIN SETTINGS {{{
"------------------------------------------------------------

" gitgutter - plugin config {{{

set updatetime=1000                 "wait how much time to detect file update
let g:gitgutter_max_signs = 500     "threshold upto which gitgutter shows sign
let g:gitgutter_highlight_lines = 1

nnoremap gn <Plug>GitGutterNextHunk
nnoremap gp <Plug>GitGutterPrevHunk
nnoremap <leader>hs <Plug>GitGutterStageHunk
nnoremap <leader>hu <Plug>GitGutterUndoHunk
nnoremap <leader>hp <Plug>GitGutterPreviewHunk            

nnoremap <leader>ggt <esc>:GitGutterToggle<cr>

if exists('&signcolumn')  " vim 7.4.2201+
  set signcolumn=yes
else
  let g:gitgutter_sign_column_always = 1
endif
"}}}


" vim-closetag - plugin config {{{
let g:closetag_filenames = '*.html,*.xhtml,*.phtml'
let g:closetag_xhtml_filenames = '*.xhtml,*.jsx'
let g:closetag_emptyTags_caseSensitive = 1
let g:closetag_shortcut = '>'               " Shortcut for closing tags, default is '>'
let g:closetag_close_shortcut = '<leader>>' " Add > at current position without closing the current tag, default is ''
"}}}


"vim notes - plugin config {{{
let g:notes_directories = ['~/dotfiles/vim/notes']
let g:notes_list_bullets = ['*', '-', '+']
let g:notes_unicode_enabled = 0
" let g:notes_suffix = '.md'
let g:notes_title_sync='change-title'
vnoremap <Leader>ns :NoteFromSelectedText<CR>
nnoremap <C-e> :edit note:
"}}}

" ack.vim - plugin config {{{
if executable('ag')
  let g:ackprg = 'ag --nogroup --nocolor --column --heading --follow --smart-case'
  "search in pwd. [!] if not given, the first occurence is jumped to.
endif

nnoremap <leader>a :Ack!<space>

" }}}

"command-t - plugin config {{{

" change pwd to root git dir
nnoremap <leader>gr :call CD_Git_Root()<cr>
" add wildignore filetypes from .gitignore
nnoremap <leader>cti :call WildignoreFromGitignore()<cr>
if has('ruby')
  " with ruby support use command-t
  " start command-t to find files in notes directory.
  nnoremap <leader>fn :CommandT /mnt/windows/projects/notes<cr>
else
  " with no ruby support in vim, use ctrl-p + ag(silver search for vim)
  let g:ctrlp_match_window = 'bottom,order:ttb'                  " top-to-bottom filename matching
  let g:ctrlp_switch_buffer = 0                                  " always open file in new buffer
  let g:ctrlp_working_path_mode = 0                              " ability to change pwd in vim session
  let g:ctrlp_user_command = 'ag %s -l --nocolor --hidden -g ""' " use ag to search 
endif

"}}}

" }}}

"------------------------------------------------------------
" AUTO COMMANDS   {{{
"------------------------------------------------------------

" group au commands: so they won't be added when vimrc sourced again
augroup autogroup
    " Remove all auto-commands from the group autogroup
    autocmd! 

    " latex compilation shell commands. req: (pdf|xe)latex
    autocmd FileType tex nnoremap <buffer> <leader>t :!pdflatex % <CR>
    autocmd FileType tex nnoremap <buffer> <leader>x :!xelatex % <CR>
    
    autocmd FocusLost * :wall          " Save on lost focus

augroup END

" }}}

"------------------------------------------------------------
" CUSTOM FUNCTIONS {{{
"------------------------------------------------------------

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


function! Git_Repo_Cdup() " Get the relative path to repo root
    "Ask git for the root of the git repo (as a relative '../../' path)
    let git_top = system('git rev-parse --show-cdup')
    let git_fail = 'fatal: Not a git repository'
    if strpart(git_top, 0, strlen(git_fail)) == git_fail
        " Above line says we are not in git repo. Ugly. Better version?
        return ''
    else
        " Return the cdup path to the root. If already in root,
        " path will be empty, so add './'
        return './' . git_top
    endif
endfunction

function! CD_Git_Root()
    execute 'cd '.Git_Repo_Cdup()
    let curdir = getcwd()
    echo 'CWD now set to: '.curdir
endfunction


" Define the wildignore from gitignore. Primarily for CommandT
function! WildignoreFromGitignore()
    silent call CD_Git_Root()
    let gitignore = '.gitignore'
    if filereadable(gitignore)
        let igstring = ''
        for oline in readfile(gitignore)
            let line = substitute(oline, '\s|\n|\r', '', "g")
            if line =~ '^#' | con | endif
            if line == '' | con  | endif
            if line =~ '^!' | con  | endif
            if line =~ '/$' | let igstring .= "," . line . "*" | con | endif
            let igstring .= "," . line
        endfor
        let execstring = "set wildignore+=".substitute(igstring,'^,','',"g")
        execute execstring
        echo 'Wildignore defined from gitignore in: '.getcwd()
    else
        echo 'Unable to find gitignore'
    endif
endfunction

function! ShowColorSchemeName()
    try
        echo g:colors_name
    catch /^Vim:E121/
        echo "default
    endtry
endfunction

" }}}

"------------------------------------------------------------
" SOURCE VIM CONFIGS  {{{
"------------------------------------------------------------

" dougblack.io/words/a-good-vimrc.html
" realpython.com/blog/python/vim-and-python-a-match-made-in-heaven/
" witkowskibartosz.com/blog/gitgutter-vim-plugin.html
" github.com/amix/vimrc/tree/master/vimrcs
" vimcasts.org/episodes/spell-checking/
" nvie.com/posts/how-i-boosted-my-vim/
" medium.com/usevim/vim-101-set-hidden-f78800142855
" devel.tech/snippets/n/vIMmz8vZ/minimal-vim-configuration-with-vim-plug/#putting-it-all-together
" naperwrimo.org/wiki/index.php?title=Vim_for_Writers
" ctoomey.com/writing/command-t-optimized/
" ddrscott.github.io/blog/2016/side-search/#haven't_checked_yet
" hackernoon.com/the-last-statusline-for-vim-a613048959b2
" r/vim

" }}}

"------------------------------------------------------------
" END
"------------------------------------------------------------
