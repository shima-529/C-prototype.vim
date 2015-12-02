function! C_prototype#make() abort
	" カーソル位置
	let s:cur = {'tate' : line('.'), 'yoko': col('.')}
	call cursor(1,1)

	" 関数の検索
	call C_prototype#get("f")

	" 配列に格納
	let s:lsttxt = [""]
	for lineNum in s:lst
		let addtxt = getline(lineNum)
		if stridx(addtxt, "main") < 0
			call add(s:lsttxt, addtxt)
		endif
	endfor

	let i = 0
	for line in s:lsttxt
		let s:lsttxt[i] = substitute(line, "{", ";", "")
		let i += 1
	endfor

	" プリプロセッサ処理の検索(最後の行にプロトタイプを置く)
	call cursor(1,1)
	let prev = 0
	while 1
		let now = search("^#", "Wc")
		if now == 0 || now == prev
			break
		endif
		let prev = now
		call cursor(line(".") + 1, 1)
	endwhile

	" 一行ずつ貼り付け
	for content in s:lsttxt
		call append(prev, content)
		let prev += 1
	endfor
	" ここでカーソルを元に戻す
	call cursor(s:cur['tate'], s:cur['yoko'])
	unlet! s:cur s:lst lineNum i now prev content
endfunction

function! C_prototype#del() abort
	" カーソル位置
	let s:cur = {'tate' : line('.'), 'yoko': col('.')}
	call cursor(1,1)

	" プロトタイプ宣言探索
	call C_prototype#get("p")

	" 一行ずつ消していく
	let i = 0
	for index in s:lst
		execute index - i . "delete"
		let i += 1
	endfor

	" ここでカーソルを元に戻す
	call cursor(s:cur['tate'], s:cur['yoko'])
	unlet! i index cur
endfunction

" 関数orプロトタイプ検索用。プロトタイプ検索時は同時にプリプロセッサ回避＆空行削除も行う。
function! C_prototype#get(param) abort
	" 検索用ワードの準備
	if a:param == "f"
		let word = ".* .*(.*) *{"
	elseif a:param == "p"
		let word = "[^\s].* .*(.*) *;"
	endif
	" 各用途用の準備
	let s:lst = []
	if a:param == "p"
		let mainpos = search(".* *main *(.*)\s*{")
		call cursor(1, 1)
	endif

	let prev = 0
	while 1
		let now = search(word, "Wc")
		call cursor(line(".") + 1, 1)

		" プロトタイプを探すときにmain関数よりも下は見ない {{{
		if a:param == "p" && now > mainpos
			break
		endif
		" }}}
		" 検索しつくしたら撤退
		if now == 0 || now == prev
			break
		endif
		" プロトタイプを探すとき、プリプロセッサ処理を誤認しないように除外 {{{
		if a:param == "p" && stridx(getline(now), "#") < 0 && now >= 2
			" 以下は空行を消す「ついで」の命令
			if getline(now - 1) == ""
				call add(s:lst, now - 1)
			endif
			call add(s:lst, now)
		endif
		" }}}
		let prev = now
		if a:param != "p"
			call add(s:lst, now)
		endif
	endwhile

	unlet! prev now word mainpos
endfunction

" refresh()用
function! C_prototype#list(param) abort
	let s:lsttxt = []
	" call add(s:lsttxt, "")
	call cursor(1, 1)
	for lineNum in s:lst
		if stridx(getline(lineNum), "main") < 0
			let addtxt = getline(lineNum)
			call add(s:lsttxt, addtxt)
		endif
	endfor

	let i = 0
	for line in s:lsttxt
		let s:lsttxt[i] = substitute(line, "{", ";", "")
		let i += 1
	endfor
	unlet! lineNum addtxt line i
endfunction

function! C_prototype#refresh() abort
	if !exists("s:lsttxt")
		let s:lsttxt = []
	endif

	let cur = { "tate" : line("."), "yoko" : col(".") }

	call cursor(1, 1)
	call C_prototype#get("p")
	call C_prototype#list("p")
	let proto = s:lsttxt

	" protoはプロトタイプの情報
	call cursor(1, 1)
	call C_prototype#get("f")
	call C_prototype#list("f")
	let func = s:lsttxt
	call insert(func, "", 0)
	
	if proto != func
		call C_prototype#del()
		call C_prototype#make()
	else
		echohl WarningMsg | echo "No prototype declarations changed." | echohl None
	endif
	call cursor(cur["tate"], cur["yoko"])
	unlet! cur now
endfunction
