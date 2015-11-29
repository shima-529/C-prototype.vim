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
	let i = 0
	let txt = [""]
	for what in lst
		let addtxt = getline(lst[i])
		if stridx(addtxt, "main") < 0
			call add(txt, addtxt)
			let txt[i] = substitute(txt[i], "{", ";", "g")	
		endif
		let i+=1
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
	" ここでカーソルを元に戻す
	call cursor(cur['tate'], cur['yoko'])

endfunction

function! C_prototype#del_prototype() abort
	" カーソル位置
	let cur = {'tate' : line('.'), 'yoko': col('.')}
	call cursor(1,1)

	let x = 0
	let posx = 1
	let tmp = search(".* .*(.*) *;")
	while 1
		if getline(tmp - 1) == ""
			execute tmp-1 . "delete"
		endif
		" ここからプロトタイプを削除
		call cursor(posx, 1)
		let tmp = search(".* .*(.*) *;")
		if tmp <= x
			break
		endif

		" main関数の位置で止める
		let mainpos0 = search('int main')
		let mainpos1 = search('void main')
		let mainpos = max([mainpos0, mainpos1])
		if tmp > mainpos
			break
		endif

		" プロトタイプ宣言部は除外
		if stridx(getline(tmp), "^#") < 0
			execute tmp . "delete"
		else
			let posx = tmp
		endif
		let x = tmp - 1
	endwhile

	" ここでカーソルを元に戻す
	call cursor(cur['tate'], cur['yoko'])
	unlet x
	unlet tmp
	unlet lst
endfunction

function! C_prototype#del() abort
	" カーソル位置
	let cur = {'tate' : line('.'), 'yoko': col('.')}
	call cursor(1,1)

	let lst = []
	let prev = 0
	while 1
		let tmp = search(".* .*(.*) *;")
		if tmp <= prev
			break
		endif
		if stridx(getline(tmp), "#") < 0
			if getline(tmp - 1) == ""
				call add(lst, tmp - 1)
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
endfunction

function! C_prototype#refresh() abort
	call C_prototype#del()
	call C_prototype#make()
endfunction
