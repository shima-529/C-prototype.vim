function! C_prototype#make() abort
	" カーソル位置
	let s:cur = {'tate' : line('.'), 'yoko': col('.')}
	call cursor(1,1)
	call C_prototype#get_lastpre()
	call cursor(s:lastpre, 1)

	call C_prototype#get_func()
	" 配列(s:func_first)に格納
	call C_prototype#assign()

	call C_prototype#replace()

	" 一行ずつ貼り付け
	echo 'mainpos: ' . s:mainpos
	call cursor(s:mainpos, 1)
	for content in s:func_first
		call append(line('.')-1, content)
	endfor
	" ここでカーソルを元に戻す
	call cursor(s:cur['tate'], s:cur['yoko'])
	unlet! content
endfunction

function! C_prototype#delete() abort
	" カーソル位置
	let s:cur = {'tate' : line('.'), 'yoko': col('.')}
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
	call cursor(s:cur['tate'], s:cur['yoko'])
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
	let s:mainpos = search('.* *main *(.*)\s*{')
endfunction

function! C_prototype#get_func() abort
	" 1行目は別扱い
	let first = search('{', 'c')
	if first > 0
		if stridx(getline(first), '	') != 0 && stridx(getline(first), '/') != 0 && stridx(getline(first), '(') > 0
			call add(s:func_begin, first)
		endif
	endif
	normal! %
	call add(s:func_end, line('.'))
	" 2行目以降
	while 1
		let tmp = search('{',)
		if tmp > first
			if stridx(getline(tmp), '	') != 0 && stridx(getline(tmp), '/') != 0 && stridx(getline(tmp), '(') > 0
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
		let tmp = substitute(getline(protoline), ';', '{', '')
		call add(s:now_proto, tmp)
	endfor
	unlet! protoline tmp
endfunction

function! C_prototype#get_lastpre() abort
	let prev = 0
	let now = search('^#', 'c')
	if now == 0
		break
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
		let addtxt = getline(lineNum)
		if stridx(addtxt, 'main') < 0
			call add(s:func_first, addtxt)
		endif
	endfor
	unlet! lineNum
endfunction

function! C_prototype#replace() abort
	let i = 0
	for line in s:func_first
		let s:func_first[i] = substitute(line, '{', ';', '')
		let i += 1
	endfor
	unlet! i line
endfunction

function! C_prototype#refresh() abort
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

	if s:now_proto == s:func_first
		echohl WarningMsg | echo 'No prototype declarations changed.' | echohl None
	else
		call C_prototype#declare()
		call C_prototype#get_main()
		call C_prototype#make()
	endif
	call cursor(s:cur['tate'], s:cur['yoko'])
	unlet! s:nowproto
endfunction

function! C_prototype#del() abort
	call cursor(1, 1)
	call C_prototype#get_main()
	call cursor(1, 1)
	call C_prototype#delete()
	call cursor(s:cur['tate'], s:cur['yoko'])
endfunction
