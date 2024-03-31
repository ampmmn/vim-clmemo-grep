" clmemogrep.vim -- A vim plugin for grepping 'Changelog Memo'.

scriptencoding utf-8

let s:saved_cpoptions=&cpoptions
set cpoptions&vim

" Check Env.
if !has('python3')"{{{
	echoerr "Required Vim compiled with +python3 or +python3/dyn"
	finish
endif
if v:version < 700
	echoerr "clmemogrep.vim requires Vim 7.0 or later."
	finish
endif"}}}



" Functions
let s:clmemogrep_init=0
function! s:python_part_init()"{{{
	" 初回のみ実行
	if s:clmemogrep_init != 0
		return
	endif
python3 << END_OF_PYTHON_PART


def clmemo_search(filePath):
	import vim,re
	
	enc           = vim.eval("&enc")
	fenc          = enc
	try:
		fenc = vim.eval("g:clmemogrep_fileencoding")
	except vim.error as e:
		fenc = enc

	end_pattern   = re.compile(vim.eval("g:clmemogrep_endpatern"))
	start_pattern = re.compile(vim.eval("g:clmemogrep_startpattern"))
	date_pattern  = re.compile(r'^(\d+?)-(\d+?)-(\d+)')
	
	year,month,day='0','0','0'
	
	# vim側にアイテム情報を渡す(アイテムが検索ワードを含むかどうかはvim側で判断)
	def insertIf(_):
		_ = _.replace(u'\\', u'\\\\').replace(u'"', u'\\"').replace(u'\n', u'\\n')
		cmdline= u'_result.insertIf("%s",%s,%s,%s)' % (_, year,month,day)
		vim.eval(cmdline.encode(enc))
	
	cur_item=''

	try:
		for line in open(filePath, "r", encoding=fenc):
			
			# 空行(=アイテム区切り)または先頭に文字列がある(=ヘッダ行の)場合
			if end_pattern.match(line):
				
				# 前行までのアイテムを評価
				insertIf(cur_item)

				# バッファをクリア
				cur_item = ''
				# ヘッダ行の場合は日付を覚えておく
				if date_pattern.match(line):
					year,month,day = date_pattern.match(line).groups()
				continue
			# アイテムヘッダに合致する場合はアイテム単位での収集を開始
			if start_pattern.match(line):
				# 前行までのアイテムを評価
				insertIf(cur_item)
				# バッファを更新
				cur_item = line.lstrip()
				continue
			cur_item += line.lstrip()
	except UnicodeError as e:
		vim.eval('_result.reportError()')

END_OF_PYTHON_PART
	let s:clmemogrep_init = 1
endfunction"}}}

let s:tmpl = {
	\ "patterns":[], "dates":[], "results":[], "exclude":[]
	\ }

" patternsにすべてマッチするなら文字列を保持
function! s:tmpl.insertIf(expr,year,month,day)"{{{

	if len(a:expr)==0 | return | endif

	for pat in self.patterns
		if a:expr !~ pat
			return 0
		endif
	endfor
	" 除外パターンに含まれるアイテムは結果に含まない
	for pat in self.exclude
		if a:expr =~ pat
			return 0
		endif
	endfor

	" datesに要素が存在する場合は、その要素が示す日付に一致するアイテムのみを追加する
	if len(self.dates) > 0
		for date in self.dates
			if a:year != date[0] || a:month != date[1] || a:day != date[2]
				continue
			endif
			let self.results += [ [a:expr,[a:year,a:month,a:day] ] ]
			return 1
			break
		endfor
		return 0
	else
		let self.results += [ [a:expr,[a:year,a:month,a:day] ] ]
		return 1
	endif
endfunction"}}}


function! s:tmpl.reportError()"{{{
	echohl ErrorMsg
	echo 'Invalid fileencoding error occurred during searching memo.'
	echohl
		
endfunction"}}}


function! s:search(filepath, keywords,exclude,dates)"{{{
	if filereadable(a:filepath) == 0
		echohl ErrorMsg
		echo a:filepath . ' : Changelog memo is not filereadable.'
		echohl
		return []
	endif
	let _result          = deepcopy(s:tmpl)
	let _result.patterns = a:keywords
	let _result.exclude  = a:exclude
	let _result.dates    = a:dates

	call s:python_part_init()
	python3 import vim
	python3 clmemo_search(vim.eval("a:filepath"))

	if len(_result.results) == 0
		echohl WarningMsg
		echo "Item not found."
		echohl
		return []
	endif

	return _result.results
endfunction"}}}

" 検索処理
" filepath:Changelogメモファイルのパス
" reverse: 結果の反転(非0で反転)
" a:000キーワードのリスト(AND検索)
function! clmemogrep#grep(filepath, reverse, ...)"{{{
	if len(a:000)==0
		return
	endif
	let results = s:search(a:filepath, a:000, [], [])
	if len(results) == 0
		return
	endif

	" カレンダー表示の更新
	call s:setCalendarSignFunction(results, 0, 0)

	if a:reverse
		call reverse(results)
	endif

	let output_winnr = s:open()

	let jumpinfo = []
	call s:print(output_winnr, results,g:clmemogrep_showheader, a:000, [jumpinfo])

	" 必要に応じてタグジャンプ用のマッピングを追加
	if exists("g:clmemogrep_Jump") && g:clmemogrep_Jump
		nnoremap <buffer><silent> q <C-w>c
		exe "noremap <buffer><silent> <cr> :call <SID>jump('".a:filepath."', line('.'))<cr>"
	endif

	" タグジャンプ実行時に検索結果データを流用するのでここでバッファローカル変数で保持しておく
	call setbufvar(winbufnr(output_winnr), "clmemogrep_jumpinfo", jumpinfo)
endfunction "}}}

" 出力バッファ & ウインドウの作成
function! s:open()"{{{

	let bname = '__ChangeLogMemoGrep'
	let cur_winnr = winnr()

	let win_height = g:clmemogrep_WindowHeight
	if g:clmemogrep_WindowHeight==0
		let win_height=""
	endif


	" バッファが存在しなければ、出力ウインドウとともに作成
	if bufexists(bname) == 0
		silent execute printf('%s %s %snew', g:clmemogrep_Direction, win_height, g:clmemogrep_Split)
		setlocal bufhidden=unload
		setlocal nobuflisted
		setlocal buftype=nofile
		setlocal nomodifiable
		setlocal noswapfile
"		setlocal nonumber
		setlocal filetype=clmemogrep
		silent file `=bname`
	else
		" バッファはウインドウ上に表示されているか? なければウインドウだけ作成
		let nr = bufnr(g:clmemogrep_outputwindow)
		let winnr = bufwinnr(nr)
		if winnr != -1
			return winnr
		endif

		execute printf('%s %d %ssplit',g:clmemogrep_Direction, win_height, g:clmemogrep_Split)
		silent execute nr 'buffer'
	endif

	execute cur_winnr 'wincmd w'

	return bufwinnr(g:clmemogrep_outputwindow)
endfunction "}}}

" 検索結果データを出力ウインドウ上に表示
function! s:print(output_winnr, results,showheader, keywords, jumpinfo)"{{{
	let [output_winnr, cur_winnr] = [a:output_winnr, winnr()]

	execute  output_winnr 'wincmd w'

	"既存の内容を全削除し、新しい内容に置き換える
	setlocal modifiable
	silent! execute 1 'delete _' line('$')

	" ヘッダ表示
	if a:showheader
			silent! call append(0, printf("Results %d items for %s", len(a:results), join(a:keywords,' ')))
	endif


	for resultitem in a:results
		let [item, date] = resultitem
		let item = substitute(item, '\r', '', 'g')

		let item_head = line("$")

		for _ in split(item, '\n')
			if g:clmemogrep_showdate!=0
				let _ = substitute(_, '^\*\s', printf('*[%04d-%02d-%02d] ', date[0],date[1],date[2]), '')
			endif
			silent! call append(line('$')-1, _)
		endfor
		if exists("g:clmemogrep_itemseparator")
			silent! call append(line('$')-1, g:clmemogrep_itemseparator)
		endif
		
		let item_tail = line("$")-1

		let a:jumpinfo[0] += [ [item_head, item_tail, date, item] ]

	endfor
	normal! 1G
	setlocal nomodified
	setlocal nomodifiable

	" シンタックスと折りたたみの設定
	"	 折りたたみ展開時に、
	"	 - アイテムが1件しかない場合
	"	 - ウインドウ内にすべて収まる場合
	"	は折りたたまない
	let use_fold = line('$') > winheight(0) && len(a:results) > 1
	call s:setupSyntaxKeywordsAndFold(a:keywords, use_fold)

	" 必要に応じて出力ウインドウにカーソルを移動
	if g:clmemogrep_setfocus == 0
		execute cur_winnr 'wincmd w'
	endif
endfunction"}}}

function! s:setupSyntaxKeywordsAndFold(keywords, use_fold)"{{{
	" 検索キーワード部のみを強調表示するシンタックスの設定
	silent! execute "syn clear CLMGKeyword"
	for _ in a:keywords
		silent! execute "syn match CLMGKeyword `" . _ . "`"
	endfor
	silent! execute "hi! link CLMGKeyword Keyword"
	" アイテム間セパレータが設定されている場合をシンタックスを設定
	silent! execute "syn clear CLMGComment"
	if exists("g:clmemogrep_itemseparator") && len(g:clmemogrep_itemseparator) > 0
		silent! execute "syn match CLMGComment `^" . g:clmemogrep_itemseparator . "$`"
		silent! execute "hi! link CLMGComment Comment"
	endif
	" 折りたたみの設定
	silent! syn clear clmemogrepItem
	if g:clmemogrep_fold != 0
		syn region clmemogrepItem start="^\*" end="\n^\*" fold transparent excludenl
		setl foldmethod=syntax
	endif
	if a:use_fold == 0
		setlocal modifiable
		silent normal 1GVGGzO
		setlocal nomodifiable
	endif
endfunction"}}}

" 指定した年月日に一致するエントリヘッダ位置を取得
function s:getpos(year,month,day)"{{{
	let pos = getpos('.')
	
	" バッファを対象に検索
	let expr = printf('^%04d-%02d-%02d', a:year, a:month, a:day)

	let searchpos = search(expr, 'w')
	if searchpos == 0
		call setpos('.', pos)
		return [0,0,0,0]
	endif

	let entrypos = getpos('.')
	call setpos('.', pos)
	return entrypos
endfunction"}}}

" calendar_signフック関数とカレンダー表示の更新
function! s:setCalendarSignFunction(results, createwindow, setfocus)"{{{
	let win_nr = winnr()

	" FIXME:重複する日付のif判定文が生成されてしまう
	let signFunc="function! g:Clmemogrep_CalendarSign(day,month,year)\n"
	for _ in a:results
		let [item, date] = _
		let signFunc.= printf("if a:year==%d && a:month==%d && a:day == %d|return '@'|endif\n", date[0], date[1], date[2])
	endfor
	let signFunc.="return 0\n"
	let signFunc.="endfunction"
	exe signFunc
	let g:calendar_sign="g:Clmemogrep_CalendarSign"

	" カレンダーウインドウの再表示
	if exists(":Calendar") == 2 && exists(":CalendarH") == 2
		let nr = bufnr('__Calendar')
		" a:createwindow値が0の場合、カレンダーバッファが可視でなければ更新しない
		if a:createwindow == 0 && bufwinnr(nr) == -1
			return
		endif
		if nr == -1
			Calendar
		else
			let dir = getbufvar(nr, 'CalendarDir')
			exe dir==0? "Calendar": "CalendarH"
		endif
	endif

	if a:setfocus==0
		execute  win_nr 'wincmd w'
	endif
endfunction"}}}

" 指定したキーワードを含むアイテムの日付をcalendar上にSign表示
function! clmemogrep#calendarSign(filepath, createwindow, ...)"{{{
	if exists(":Calendar") == 0
		echohl WarningMsg
		echo 'calendar.vim not exists.'
		echohl
		return
	endif
	let results = s:search(a:filepath, a:000, [], [])
	if len(results) == 0
		return
	endif
	return s:setCalendarSignFunction(results, a:createwindow, 1)
endfunction
"}}}

" ChangeLogメモを別のウインドウに開く。既に開かれている場合は何もしない
function! s:openFile(filepath, dir)"{{{
	" a:filepathを表示しているウインドウがなければ、ウインドウを作成
	" a:base_winnrのウインドウの向きに合わせて、隣接する形で作成します。
	let base_winnr = winnr()

	let nr = bufnr(a:filepath)
	let cur_nr = bufwinnr(nr)
	if cur_nr == -1
		if a:dir == 'H'
			execute "normal! \<c-w>k"
			let cur_nr = winnr()
			if cur_nr == base_winnr
				execute "normal! \<c-w>j"
				let cur_nr = winnr()
				if cur_nr == base_winnr
					new
					let cur_nr = winnr()
				endif
			endif
		else
			execute "normal! \<c-w>l"
			let cur_nr = winnr()
			if cur_nr == base_winnr
				execute "normal! \<c-w>h"
				let cur_nr = winnr()
				if cur_nr == base_winnr
					rightbelow vnew
					let cur_nr = winnr()
				endif
			endif
		endif
		execute "edit" a:filepath
		let nr = bufnr(".")
	endif
	execute cur_nr 'wincmd w'
	silent! execute nr 'buffer'

	return [cur_nr, nr]
endfunction"}}}

" 対応するChangeLogメモのアイテムヘッダ位置にジャンプする
function! s:jump(filepath, line)"{{{

	let jumpinfo = getbufvar('__ChangeLogMemoGrep', 'clmemogrep_jumpinfo')
	if type(jumpinfo) == type('')
		return
	endif

	for _ in jumpinfo
		let [head,tail] = [ _[0], _[1] ]
		if a:line < head || tail < a:line
			continue
		endif

		let [date, item] = [ _[2], _[3] ]

		let [win_nr, buf_nr] = s:openFile(a:filepath, g:clmemogrep_Split!='v'?'H':'V')
		if win_nr == -1
			return 
		endif

		let datestring = printf('^%04d-%02d-%02d', date[0], date[1], date[2])
		if search(datestring, 'w') == 0
			return
		endif
		let patstring = split(substitute(item, '\r', '\n', 'g'), '\n')[0]
		" *,[,]などの文字をエスケープする
		let patstring = substitute(patstring, '\(\[\|\]\|\*\)', '\\\1', 'g')
		if search(patstring, 'W') == 0
			return
		endif
		return
	endfor
endfunction"}}}


" calendar.vimのアクションフック用関数
" ChangeLogメモ上の指定日付のエントリヘッダにジャンプ
function! CalendarActionCLMemo(day, month, year, week, dir)"{{{
	" NOTE:前提:ここに処理が及ぶ時点で、カレントウインドウは__Calendar
	call s:openFile(g:clmemogrep_changelogfilepath, a:dir)

	" ChangeLogメモの指定日付にジャンプ
	let entry_pos = s:getpos(a:year,a:month,a:day)
	if entry_pos == [0,0,0,0]
		return
	endif
	call setpos(".", entry_pos)
	execute "normal! z\<cr>"
endfunction"}}}

" nowが指す日から、dates日前の日付のリストを列挙する
function! s:enumPastDays(dates, now)"{{{
	let l:dates = []
	for _ in a:dates
		let dayseconds = 60*60*24
		let dayOfWeek = 0+strftime('%w', a:now - dayseconds*_)
		let l:dates += [ split(strftime('%Y %m %d', a:now - dayseconds*_), ' ') ]
	endfor
	return l:dates
endfunction"}}}

" 指定日数前のエントリを作成
" filepath : ChangeLogメモファイルのパス
" reverse  : 結果の反転(非0で反転)
" now      : 現在の時刻を表すlocaltime値
" a:000    : 日数リスト(N日前のエントリを表示)
function! g:CLMemoEnum(filepath, reverse, keywords, exclude, dates, now)"{{{
	let l:dates = s:enumPastDays(a:dates, a:now)
	let dayOfWeek = 0+strftime('%w', a:now)
	if dayOfWeek == 1
		" 実行時の曜日が月曜日の場合は、その前日である日曜日の分のリマインドも行う
		let l:dates += s:enumPastDays(a:dates, a:now - 3600*24)
	elseif dayOfWeek == 5
		" 同様に、当日が金曜日の場合は、その翌日である土曜日の分のリマインドも行う
		let l:dates += s:enumPastDays(a:dates, a:now + 3600*24)
	endif

	let results = s:search(a:filepath, a:keywords, a:exclude, l:dates)

	if len(results) == 0
		echohl WarningMsg
		echo "Item not found."
		echohl
		return []
	endif

	if a:reverse != 0
		call reverse(results)
	endif

	let output_winnr = s:open()

	let jumpinfo = []
	call s:print(output_winnr, results, 0,[], [jumpinfo])

	" 必要に応じてタグジャンプ用のマッピングを追加
	if exists("g:clmemogrep_Jump") && g:clmemogrep_Jump
		nnoremap <buffer><silent> q <C-w>c
		exe "noremap <buffer><silent> <cr> :call <SID>jump('".a:filepath."', line('.'))<cr>"
	endif
	" タグジャンプ実行時に検索結果データを流用するのでここでバッファローカル変数で保持しておく
	call setbufvar(winbufnr(output_winnr), "clmemogrep_jumpinfo", jumpinfo)
endfunction"}}}


let &cpoptions=s:saved_cpoptions
unlet s:saved_cpoptions

