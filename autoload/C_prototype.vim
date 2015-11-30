function! C_prototype#make() abort
	" カーソル位置
	let cur = {'tate' : line('.'), 'yoko': col('.')}
	call cursor(1,1)

	" 関数の検索
	let x = 0
	let i = 0
	let lst = []
	while 1
		let tmp = search(".* .*(.*) *{")
		if tmp <= x
			break
		endif
		call add(lst, tmp)
		let x = tmp
	endwhile
	unlet x
	unlet tmp

	" 配列に格納
	let txt = [""]
	for what in lst
		let addtxt = getline(what)
		if stridx(addtxt, "main") < 0
			call add(txt, addtxt)
		endif
	endfor

	let i = 0
	for line in txt
		let txt[i] = substitute(line, "{", ";", "")
		let i += 1
	endfor

	" プリプロセッサ処理の検索
	call cursor(1,1)
	let x = 0
	while 1
		let tmp = search("^#")
		if tmp <= x
			break
		endif
		let x = tmp
	endwhile

	" 一行ずつ貼り付け
	for content in txt
		call append(x, content)
		let x += 1
	endfor
	unlet x
	unlet tmp
	unlet txt
	" ここでカーソルを元に戻す
	call cursor(cur['tate'], cur['yoko'])

endfunction

function! C_prototype#del() abort
	" カーソル位置
	let cur = {'tate' : line('.'), 'yoko': col('.')}
	call cursor(1,1)

	let lst = []
	let prev = 0
	let mainpos = search(".*main *(.*)\s*{")
	call cursor(1,1)

	" プロトタイプ宣言探索
	let flag = 0
	while 1
		if flag == 0
			let tmp = search("[^\s].* .*(.*) *;", "c")
			let flag += 1
		else
			let tmp = search("[^\s].* .*(.*) *;")
		endif
		if tmp > mainpos
			break
		endif
		if tmp <= prev
			break
		endif
		if stridx(getline(tmp), "#") < 0
			if tmp - 1 > 0
				if getline(tmp - 1) == ""
					call add(lst, tmp - 1)
				endif
			endif
			call add(lst, tmp)
		endif
		let prev = tmp
	endwhile

	let i = 0
	for index in lst
		execute index - i . "delete"
		let i += 1
	endfor

	" ここでカーソルを元に戻す
	call cursor(cur['tate'], cur['yoko'])
	unlet cur
	unlet prev
	unlet tmp
	unlet lst
	unlet i
endfunction

function! C_prototype#refresh() abort
	call C_prototype#del()
	call C_prototype#make()
endfunction
