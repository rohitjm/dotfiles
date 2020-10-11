" Specify a directory for plugins

set number " set line numbers by default

call plug#begin('~/.vim/plugged')

Plug 'neoclide/coc.nvim', {'branch': 'release'}
Plug 'scrooloose/nerdtree'
Plug 'junegunn/fzf', { 'dir': '~/.vim/plugged/.fzf', 'do': './install --all' }
Plug 'junegunn/fzf.vim'


call plug#end()

let g:NERDTreeChDirMode = 2  " Change cwd to parent node
let g:NERDTreeMinimalUI = 1  " Hide help text

nnoremap <silent> <leader>f :FZF<cr>
nnoremap <silent> <leader>F :FZF ~<cr>

nnoremap <leader>n :NERDTreeToggle<CR>
nnoremap <leader>N :NERDTreeFind<CR>

inoremap kj <ESC>

" Keeps the history of previous searches.
" You can use ctrl-n or ctr-p to navigate the history on a FZF window
let g:fzf_history_dir = '~/.local/share/fzf-history'
