" vim: noexpandtab

let s:cursor_pos_stack = []

function! s:store_current_cursor()
	call add(s:cursor_pos_stack, [line('.'), col('.')])
endfunction

function! s:load_current_cursor()
	let [l, c] = remove(s:cursor_pos_stack, -1)
	call cursor(l, c)
endfunction

function! s:make() abort
	" カーソル位置
	call s:store_current_cursor()

	call cursor(1,1)
	" call s:get_lastpre()
	" call cursor(s:lastpre, 1)
	call cursor(s:mainpos, 1)

	call s:get_func()
	" 配列(s:func_first)に格納
	call s:assign()
	let g:c_prototype_insert_point = get(g:, 'c_prototype_insert_point', 1)

	let added_lines = s:func_first

	" Add blank lines to line str list.
	for i in range(0, g:c_prototype_insert_point - 1)
		call add(added_lines, '')
	endfor

	" Append prototypes.
	call append(s:mainpos - 1, added_lines)

	" ここでカーソルを元に戻す
	call s:load_current_cursor()
endfunction

function! s:delete() abort
	" カーソル位置
	call s:store_current_cursor()
	call cursor(1,1)

	" プロトタイプ宣言探索
	call s:get_proto()

	if empty(s:proto_line) == 1
		return
	endif

	" 一行ずつ消していく
	let i = -1
	for index in s:proto_line
		let i += 1
		execute 'keepjumps ' . (index - i) . 'delete'
	endfor

	let line_num = s:proto_line[0]
	if getline(line_num) == ''
		let g:c_prototype_insert_point = get(g:, 'c_prototype_insert_point', 1)
		execute 'keepjumps ' . line_num . 'delete' . g:c_prototype_insert_point
	endif

	" ここでカーソルを元に戻す
	call s:load_current_cursor()
endfunction

function! s:declare() abort
	" begin, first : 行情報
	let s:func_begin = []
	let s:func_end   = []
	let s:proto_line = []
	" first : 行の中身
	let s:func_first = []
	" プリプロセッサの最終行
	let s:lastpre = 1

	let s:mainpos = 0

	let s:now_proto = []
endfunction

" get系は実行前後にカーソル位置調整よろしく
function! s:get_main() abort
	let s:mainpos = search('.* *main *(.*)\s*\n*{', 'n')
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
			call add(s:func_begin, first)
		endif
	endif

	keepjumps normal! %
	call add(s:func_end, line('.'))

	" 2行目以降
	while 1
		let tmp = search('{',)
		if tmp > first
			let line_str = s:get_function_declare_line(tmp)
			if s:is_valid_function_declare_str(line_str) == 1
				call add(s:func_begin, tmp)
			endif
		else
			break
		endif
		keepjumps normal! %
		call add(s:func_end, line('.'))
	endwhile
endfunction

function! s:get_proto() abort
	let s:proto_line = []
	let prev = 0
	while 1
		let now = search('[^\s].* .*(.*) *;', 'n')
		if now > s:mainpos || now <= prev
			break
		endif
		if now == 0
			let s:proto_line = []
			break
		endif
		call add(s:proto_line, now)
		let prev = now

		call cursor(now + 1, 1)
	endwhile
endfunction

function! s:get_protolist() abort
	call add(s:now_proto, '')
	for protoline in s:proto_line
		let tmp = getline(protoline)
		call add(s:now_proto, tmp)
	endfor
endfunction

function! s:get_lastpre() abort
	let prev = 0
	let now = search('^#', 'c')
	if now == 0
		return
	endif
	let prev = now
	while 1
		let now = search('^#')
		if now <= prev || now > s:mainpos
			let s:lastpre = prev
			break
		endif
		let prev = now
		call cursor(line('.') + 1, 1)
	endwhile
	unlet! prev now
endfunction

function! s:assign() abort
	let g:c_prototype_remove_var_name = get(g:, 'c_prototype_remove_var_name', 0)

	let s:func_first = []
	for line_num in s:func_begin
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
			call add(s:func_first, str)
		endif
	endfor
endfunction

function! C_prototype#refresh() abort
	call s:store_current_cursor()
	call s:declare()
	call cursor(1, 1)
	call s:get_main()
	call cursor(1, 1)
	" call s:get_lastpre()
	call cursor(s:mainpos, 1)
	call s:get_func()
	call s:assign()

	call cursor(1, 1)
	call s:get_proto()
	call s:get_protolist()
	" echo s:now_proto
	" echo s:func_first
	if s:now_proto == s:func_first
		echohl WarningMsg | echo 'No prototype declarations changed.' | echohl None
	else
		call C_prototype#del()
		call s:declare()
		call s:get_main()
		call s:make()
	endif

	call s:load_current_cursor()
endfunction

function! C_prototype#del() abort
	call s:store_current_cursor()

	call cursor(1, 1)
	call s:get_main()
	call cursor(1, 1)
	call s:delete()

	call s:load_current_cursor()
endfunction
