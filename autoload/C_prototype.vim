" vim: noexpandtab

let s:cursor_pos_stack = []

function! s:store_current_cursor()
	call add(s:cursor_pos_stack, [line('.'), col('.')])
endfunction

function! s:load_current_cursor()
	let [l, c] = remove(s:cursor_pos_stack, -1)
	call cursor(l, c)
endfunction

function! C_prototype#make() abort
	" カーソル位置
	call s:store_current_cursor()

	call cursor(1,1)
	call C_prototype#get_lastpre()
	call cursor(s:lastpre, 1)

	call C_prototype#get_func()
	" 配列(s:func_first)に格納
	call C_prototype#assign()

	" 一行ずつ貼り付け
	" ==================
	" MODIFIED
	let flag = 1
	if getline(s:mainpos-1) != ''
		call append(s:mainpos-1, '')
		let flag = 0
	endif
	call cursor(s:mainpos - 1 - flag, 1)
	" call cursor(s:mainpos, 1)
	for content in s:func_first
		" call append(line('.')-1, content)
		call append(line('.'), content)
		normal! j
	endfor
	unlet! flag
	" ==================

	" ここでカーソルを元に戻す
	call s:load_current_cursor()

	unlet! content
endfunction

function! C_prototype#delete() abort
	" カーソル位置
	call s:store_current_cursor()
	call cursor(1,1)

	" プロトタイプ宣言探索
	call C_prototype#get_proto()

	" 一行ずつ消していく
	let i = -1
	for index in s:proto_line
		let i += 1
		execute index - i . 'delete'
	endfor
	if i != -1 && getline(s:proto_line[0]-1) == ''
		execute s:proto_line[0] - 1 . 'delete'
	endif

	" ここでカーソルを元に戻す
	call s:load_current_cursor()
	unlet! i index
endfunction

function! C_prototype#declare() abort
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
function! C_prototype#get_main() abort
	let s:mainpos = search('.* *main *(.*)\s*\n*{')
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

function! C_prototype#get_func() abort
	" 1行目は別扱い
	let first = search('{', 'c')
	if first > 0
		let line_str = s:get_function_declare_line(first)
		if s:is_valid_function_declare_str(line_str) == 1
			call add(s:func_begin, first)
		endif
	endif

	normal! %
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
		normal! %
		call add(s:func_end, line('.'))
	endwhile
	unlet! first tmp
endfunction

function! C_prototype#get_proto() abort
	let s:proto_line = []
	let prev = 0
	while 1
		let now = search('[^\s].* .*(.*) *;')
		if now > s:mainpos || now <= prev
			break
		endif
		if now == 0
			let s:proto_line = []
			break
		endif
		call add(s:proto_line, now)
		let prev = now
	endwhile
	unlet! prev now
endfunction

function! C_prototype#get_protolist() abort
	call add(s:now_proto, '')
	for protoline in s:proto_line
		" ==================
		" MODIFIED
		let tmp = getline(protoline)
		" let tmp = substitute(getline(protoline), ';', '{', '')
		" ==================
		call add(s:now_proto, tmp)
	endfor
	unlet! protoline tmp
endfunction

function! C_prototype#get_lastpre() abort
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

function! C_prototype#assign() abort
	let s:func_first = ['']
	for lineNum in s:func_begin
		let addtxt = s:get_function_declare_line(lineNum)
		let addtxt = matchstr(addtxt, '\%(;}\)\@<!\%(\w\+\s\+\)\+\%(\w\+(.*)\)\%(\s*{\)\@=') . ';'
		let addtxt = substitute(addtxt , '\s*{.*', '', 'g')
		if stridx(addtxt, 'main') < 0
			call add(s:func_first, addtxt)
		endif
	endfor
	unlet! lineNum
endfunction

function! C_prototype#refresh() abort
	call s:store_current_cursor()
	call C_prototype#declare()
	call cursor(1, 1)
	call C_prototype#get_main()
	call cursor(1, 1)
	call C_prototype#get_lastpre()
	call cursor(s:lastpre, 1)
	call C_prototype#get_func()
	call C_prototype#assign()

	call cursor(1, 1)
	call C_prototype#get_proto()
	call C_prototype#get_protolist()
	" echo s:now_proto
	" echo s:func_first
	if s:now_proto == s:func_first
		echohl WarningMsg | echo 'No prototype declarations changed.' | echohl None
	else
		" ==================
		" MODIFIED
		call C_prototype#del()
		" ==================
		call C_prototype#declare()
		call C_prototype#get_main()
		call C_prototype#make()
	endif

	call s:load_current_cursor()
	unlet! s:now_proto
endfunction

function! C_prototype#del() abort
	call s:store_current_cursor()

	call cursor(1, 1)
	call C_prototype#get_main()
	call cursor(1, 1)
	call C_prototype#delete()

	call s:load_current_cursor()
endfunction
