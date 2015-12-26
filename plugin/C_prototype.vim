"=============================================================================
" File: C-prototype.vim
" Author: shima-529
" Created: 2015-11-28
"=============================================================================

scriptencoding utf-8

if exists('g:loaded_C_prototype')
    finish
endif
let g:loaded_C_prototype = 1

let s:save_cpo = &cpo
set cpo&vim

command! -nargs=0 CPrototypeMake   call C_prototype#refresh()
command! -nargs=0 CPrototypeDelete call C_prototype#del()

nnoremap <silent> <Plug>(c-prototype-make)   :<C-u>CPrototypeMake<CR>
nnoremap <silent> <Plug>(c-prototype-delete) :<C-u>CPrototypeDelete<CR>

let g:c_prototype_no_default_keymappings = get(g:, 'c_prototype_no_default_keymappings', 0)
if g:c_prototype_no_default_keymappings == 0
    nnoremap <silent> z  :<C-u>CPrototypeMake<CR>
    nnoremap <silent> dz :<C-u>CPrototypeDelete<CR>
endif

let &cpo = s:save_cpo
unlet s:save_cpo
