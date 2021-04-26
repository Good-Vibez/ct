call plug#begin(stdpath('data') . '/plugged')

Plug 'ycm-core/YouCompleteMe', { 'do': './install.py' }
Plug 'tpope/vim-sensible'
Plug 'tpope/vim-sleuth'
Plug 'rust-lang/rust.vim'
Plug 'google/vim-jsonnet'
Plug 'kyoz/purify', { 'rtp': 'vim' }
Plug 'relastle/bluewery.vim'
Plug 'preservim/nerdtree'
Plug 'rafi/awesome-vim-colorschemes'
Plug 'ron-rs/ron.vim'

Plug 'junegunn/fzf', { 'do': { -> fzf#install() } }
"Plug 'junegunn/fzf.vim'

call plug#end()

"nmap <C-p> :call fzf#run({'sink':'e','source':'git ls-files .','window':{'width': 0.9,'height': 0.6}})<CR>
set termguicolors
set number
colorscheme apprentice
