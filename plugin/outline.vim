vim9script

import "../autoload/outline.vim" as main

command! OutlineOpen silent main.Open()
command! OutlineClose silent main.Close()
command! OutlineToggle silent main.Toggle()

# temp
nnoremap <silent> <leader><leader> :OutlineToggle<cr>

