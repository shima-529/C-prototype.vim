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

nnoremap <silent> z :call C_prototype#refresh()<CR>
nnoremap <silent> dz :call C_prototype#del()<CR>

let &cpo = s:save_cpo
unlet s:save_cpo
