" Variables List ==============================================
" l = line(s)  c = content(s)
" s:l_func_beg    : 各関数の先頭行
" s:l_func_end    : 各関数の末行
" s:l_protos      : (main関数より上で)プロトタイプ宣言のある行
" s:c_func_first  : 各関数の先頭行の中身
" s:l_lastpp      : プリプロセッサの最終行
" s:l_mainpos     : main関数の位置
" s:c_now_proto   : 現在のプロトタイプ宣言の中身
" =============================================================

let s:cursor_pos_stack = []
function! s:store_current_cursor()
	call add(s:cursor_pos_stack, [line('.'), col('.')])
endfunction

function! s:load_current_cursor()
	let [l, c] = remove(s:cursor_pos_stack, -1)
	call cursor(l, c)
endfunction

function! s:make() abort
	call s:store_current_cursor()
	call cursor(1,1)
	" call s:get_lastpre()

	call s:get_func()
	" 配列(s:c_func_first)に格納
	call s:assign()
	let g:c_prototype_insert_point = get(g:, 'c_prototype_insert_point', 1)

	let added_lines = s:c_func_first
	" echo added_lines

	" Add blank lines to line str list.
	for i in range(0, g:c_prototype_insert_point - 1)
		call add(added_lines, '')
	endfor
	" Append prototypes.
	call append(s:l_mainpos - 1, added_lines)

	call s:load_current_cursor()
endfunction

function! s:delete() abort
	" カーソル位置
	call s:store_current_cursor()
	call cursor(1,1)

	" プロトタイプ宣言探索
	call s:get_proto()

	if empty(s:l_protos) == 1
		return
	endif

	" 一行ずつ消していく
	let i = -1
	for index in s:l_protos
		let i += 1
		execute 'keepjumps ' . (index - i) . 'delete'
	endfor

	let line_num = s:l_protos[0]
	if getline(line_num) == ''
		let g:c_prototype_insert_point = get(g:, 'c_prototype_insert_point', 1)
		execute 'keepjumps ' . line_num . 'delete' . g:c_prototype_insert_point
	endif

	" ここでカーソルを元に戻す
	call s:load_current_cursor()
endfunction

function! s:init() abort
	let s:l_func_beg   = []
	let s:l_func_end   = []
	let s:l_protos     = []
	let s:c_func_first = []
	let s:l_lastpp = 1
	let s:l_mainpos = 0
	let s:c_now_proto = []
endfunction

" get系は実行前後にカーソル位置調整よろしく
function! s:get_main() abort
	call s:store_current_cursor()
	call cursor(1, 1)
	let s:l_mainpos = search('.* *main *(.*)\s*\n*{', 'n')
	call s:load_current_cursor()
endfunction

function! s:get_function_declare_line(line_number) abort
	let margin = 2

	let line_begin = a:line_number - margin
	let line_end = a:line_number + margin
	let str = ''
	for i in range(line_begin, line_end)
		let str .= substitute(getline(i), '\n', '', 'g')
	endfor

	return str
endfunction

function! s:is_valid_function_declare_str(str) abort
	if (stridx(a:str, '	') != 0) && (stridx(a:str, '/') != 0) && (0 < stridx(a:str, '('))
		return 1
	endif

	return 0
endf

function! s:get_func() abort
	" 1行目は別扱い
	let first = search('{', 'c')
	if first > 0
		let line_str = s:get_function_declare_line(first)
		if s:is_valid_function_declare_str(line_str) == 1
			call add(s:l_func_beg, first)
		endif
	endif

	keepjumps normal! %
	call add(s:l_func_end, line('.'))

	" 2行目以降
	while 1
		let tmp = search('{',)
		if tmp > first
			let line_str = s:get_function_declare_line(tmp)
			if s:is_valid_function_declare_str(line_str) == 1
				call add(s:l_func_beg, tmp)
			endif
		else
			break
		endif
		keepjumps normal! %
		call add(s:l_func_end, line('.'))
	endwhile
endfunction

function! s:get_proto() abort
	let s:c_protos = []
	let prev = 0
	while 1
		let now = search('[^\s].* .*(.*) *;')
		if now > s:l_mainpos || now <= prev
			break
		endif
		if now == 0
			let s:c_protos = []
			break
		endif
		call add(s:l_protos, now)
		let prev = now
	endwhile
endfunction

function! s:get_protolist() abort
	call add(s:c_now_proto, '')
	for protoline in s:l_protos
		let tmp = getline(protoline)
		call add(s:c_now_proto, tmp)
	endfor
endfunction

function! s:get_lastpre() abort
	call s:store_current_cursor()
	let prev = 0
	let now = search('^#', 'c')
	if now == 0
		return
	endif
	let prev = now
	while 1
		let now = search('^#')
		if now <= prev || now > s:l_mainpos
			let s:l_lastpp = prev
			break
		endif
		let prev = now
		call cursor(line('.') + 1, 1)
	endwhile
	call s:load_current_cursor()
endfunction

function! s:assign() abort
	let g:c_prototype_remove_var_name = get(g:, 'c_prototype_remove_var_name', 0)

	let s:c_func_first = []
	for line_num in s:l_func_beg
		let str = s:get_function_declare_line(line_num)
		let str = substitute(str, '\s*{.*', '', 'g')
		let str = matchstr(str, '\%([0-9a-zA-Z_*]\+\s\)\+\w\+(.*)') . ';'

		" If option is enable, remove function argument variables.
		if g:c_prototype_remove_var_name == 1
			if match(str, '(\s*void\s*)') == -1
				let str = substitute(str, '\s*\w\+\s*\ze[,)]', '', 'g')
			endif
		endif

		if stridx(str, 'main') == -1
			call add(s:c_func_first, str)
		endif
	endfor
endfunction

function! C_prototype#refresh() abort
	call s:init()
	call s:get_main()
	call s:get_lastpre()
	call cursor(s:l_lastpp, 1)
	call s:get_func()
	call s:assign()

	call cursor(1, 1)
	call s:get_proto()
	call s:get_protolist()
	call remove(s:c_now_proto, 0)
	" echo s:c_now_proto
	" echo s:c_func_first
	if s:c_now_proto == s:c_func_first
		echohl WarningMsg | echo 'No prototype declarations changed.' | echohl None
	else
		call C_prototype#del()
		call s:init()
		call s:get_main()
		call s:make()
	endif
endfunction

function! C_prototype#del() abort
	call s:init()
	call s:get_main()
	call s:delete()
endfunction

" Experimental(not recommended)
function! C_prototype#makeHeader() abort
	call s:init()
	call s:get_func()
	call s:assign()
	:new
	call append(1, s:c_func_first)
endfunction
