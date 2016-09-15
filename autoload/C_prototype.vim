" 命名規則-----------
" snake_case : 関数名
" camelCase  : 変数名
" -------------------
" Variables List ==============================================
" s:funcBegLines    : 各関数の先頭行
" s:funcEndLines    : 各関数の末行
" s:prototypeLines      : (main関数より上で)プロトタイプ宣言のある行
" s:funcNewPrototypes  : 各関数の先頭行の中身
" s:lastPreprocessLine      : プリプロセッサの最終行
" s:mainPosLine     : main関数の位置
" s:funcPresentPrototypes   : 現在のプロトタイプ宣言の中身
" =============================================================

" Cursor {{{
let s:cursorPosStack = []
function! s:store_current_cursor()
	call add(s:cursorPosStack, [line('.'), col('.')])
endfunction

function! s:load_current_cursor()
	let [l, c] = remove(s:cursorPosStack, -1)
	call cursor(l, c)
endfunction
" }}}
" Magic {{{
function! s:set_magic() abort
	let s:magicStatus = &magic
	set magic
endfunction
function! s:revert_magic() abort
	if s:magicStatus == 0
		set nomagic
	endif
endfunction
" }}}
function! s:init_variables() abort " {{{
	let s:funcBegLines   = []
	let s:funcEndLines   = []
	let s:prototypeLines     = []
	let s:funcNewPrototypes = []
	let s:lastPreprocessLine = 1
	let s:mainPosLine = 0
	let s:funcPresentPrototypes = []
endfunction
" }}}
function! s:get_mainpos() abort " {{{
	call s:store_current_cursor()
	call cursor(1, 1)
	let s:mainPosLine = search('.* *main *(.*)\s*\n*{', 'n')
	call s:load_current_cursor()
endfunction
" }}}
function! s:get_preprocess_below_main_lastline() abort " {{{
	call s:store_current_cursor()
	call cursor(1, 1)

	let prevMatchLine = -1
	let matchLine = 0
	while prevMatchLine < matchLine && matchLine < s:mainPosLine
		let prevMatchLine = matchLine
		let matchLine = search('^#', 'c')
		call cursor(line('.') + 1, 1)
	endwhile

	let s:lastPreprocessLine = prevMatchLine
	call s:load_current_cursor()
endfunction
" }}}
function! s:get_func_lines() abort " {{{
	call s:store_current_cursor()
	call cursor(1, 1)

	let prevMatchLine = -1
	let matchLine = 0
	while prevMatchLine < matchLine
		let prevMatchLine = matchLine
		let matchLine = search('^[^//|/*]\w*.*(.*)\s*\n*{', 'c')
		let lineContent = s:get_func_linestion_declare_line(matchLine)
		if s:is_valid_function_declare_str(lineContent) == 1
			call add(s:funcBegLines, matchLine)
		endif

		call search('{')
		keepjumps normal! %

		call add(s:funcEndLines, line('.'))
	endwhile

	call s:load_current_cursor()
endfunction
" }}}
function! s:pasteAllPrototypes_new_prototype_string() abort " {{{
	let g:c_prototype_remove_var_name = get(g:, 'c_prototype_remove_var_name', 0)

	let s:funcNewPrototypes = []
	for lineNum in s:funcBegLines
		if lineNum == s:mainPosLine
			continue
		endif

		" FIXME
		let lineNumStr = s:get_func_linestion_declare_line(lineNum)
		let lineNumStr = substitute(lineNumStr, '\s*{.*', '', 'g')
		let lineNumStr = matchstr(lineNumStr, '\%([0-9a-zA-Z_*]\+\W*\s\W*\)\+\w\+\s*(.*)') . ';'

		" If option is enabled, remove function argument variables.
		" If option is enabled and lineNumStr does not contain void (i.e. if not void-parameter function)
		if g:c_prototype_remove_var_name == 1 && match(lineNumStr, '(\s*void\s*)') == -1
			let lineNumStr = substitute(lineNumStr, '\s*\w\+\s*\ze[,)]', '', 'g')
		endif

		call add(s:funcNewPrototypes, lineNumStr)
	endfor
endfunction
" }}}

function! s:search_present_prototype_line_numbers() abort " {{{
	call s:store_current_cursor()
	call cursor(1, 1)

	let prevMatchLine = -1
	let matchLine = 0
	while prevMatchLine < matchLine && matchLine < s:mainPosLine
		if matchLine != 0
			call add(s:prototypeLines, matchLine)
		endif
		let prevMatchLine = matchLine
		let matchLine = search('[^\s].* .*(.*) *;', 'c')
		call cursor(line('.') + 1, 1)
	endwhile
	call s:load_current_cursor()
endfunction
" }}}
function! s:pasteAllPrototypes_present_prototype_string() abort " {{{
	" call add(s:funcPresentPrototypes, '')
	for protoline in s:prototypeLines
		let tmp = getline(protoline)
		call add(s:funcPresentPrototypes, tmp)
	endfor
endfunction
" }}}

function! s:pasteAllPrototypes() abort " {{{
	call s:store_current_cursor()
	call cursor(1,1)

	call s:get_func_lines()
	" 配列(s:funcNewPrototypes)に格納
	call s:pasteAllPrototypes_new_prototype_string()
	let g:c_prototype_insert_point = get(g:, 'c_prototype_insert_point', 1)

	let newPrototypes_copy = s:funcNewPrototypes

	" Add blank lines to line str list.
	for i in range(0, g:c_prototype_insert_point - 1)
		call add(newPrototypes_copy, '')
	endfor
	" Append prototypes.
	call append(s:mainPosLine - 1, newPrototypes_copy)

	call s:load_current_cursor()
endfunction
" }}}

function! s:deletePrototypes() abort " {{{
	" カーソル位置
	call s:store_current_cursor()
	call cursor(1,1)

	" プロトタイプ宣言探索
	call s:search_present_prototype_line_numbers()

	if empty(s:prototypeLines) == 1
		return
	endif

	" 一行ずつ消していく
	let i = -1
	for index in s:prototypeLines
		let i += 1
		execute 'keepjumps ' . (index - i) . 'delete'
	endfor

	let line_num = s:prototypeLines[0]
	if getline(line_num) == ''
		let g:c_prototype_insert_point = get(g:, 'c_prototype_insert_point', 1)
		execute 'keepjumps ' . line_num . 'delete' . g:c_prototype_insert_point
	endif

	" ここでカーソルを元に戻す
	call s:load_current_cursor()
endfunction
" }}}
function! s:get_func_linestion_declare_line(line_number) abort " {{{
	let margin = 2

	let line_begin = a:line_number - margin
	let line_end = a:line_number + margin
	let str = ''
	for i in range(line_begin, line_end)
		if match(getline(i), '\s*/') < 0
			let str .= substitute(getline(i), '\n', '', 'g')
		endif
	endfor

	return str
endfunction
" }}}
function! s:is_valid_function_declare_str(str) abort " {{{
	if (stridx(a:str, '	') != 0) && (stridx(a:str, '/') != 0) && (0 != stridx(a:str, '(')) && (stridx(a:str, '{') >= 0)
		return 1
	endif

	return 0
endfunction
" }}}

function! C_prototype#refresh() abort
	call s:store_current_cursor()
	call s:set_magic()
	" For all
	call s:init_variables()
	call s:get_mainpos()
	call s:get_preprocess_below_main_lastline()

	" For present prototypes
	call s:search_present_prototype_line_numbers()
	call s:pasteAllPrototypes_present_prototype_string()

	" For new prototypes
	call cursor(s:lastPreprocessLine, 1)
	call s:get_func_lines()
	call s:pasteAllPrototypes_new_prototype_string()

	" echo s:funcPresentPrototypes
	" echo s:funcNewPrototypes
	if s:funcPresentPrototypes == s:funcNewPrototypes
		echohl WarningMsg | echo 'No prototype declarations changed.' | echohl None
	else
		call C_prototype#del()
		call s:init_variables()
		call s:get_mainpos()
		call s:pasteAllPrototypes()
	endif
	call s:revert_magic()
	call s:load_current_cursor()
endfunction

function! C_prototype#del() abort
	call s:store_current_cursor()
	call s:set_magic()

	call s:init_variables()
	call s:get_mainpos()
	call s:deletePrototypes()

	call s:revert_magic()
	call s:load_current_cursor()
endfunction

" Experimental(not recommended)
function! C_prototype#make_header() abort
	call s:set_magic()
	call s:init_variables()
	call s:get_func_lines()
	call s:pasteAllPrototypes_new_prototype_string()
	:new
	call append(1, s:funcNewPrototypes)
	call s:revert_magic()
endfunction
