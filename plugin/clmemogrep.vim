" clmemogrep.vim -- A vim plugin for grepping 'Changelog Memo'.
" Changelog Memo is a kind of concept that writting memo into one text file.
" For more details, see http://0xcc.net/unimag/1/ (written in Japanse).
" 
" version : 0.0.6
" author : ampmmn(htmnymgw <delete>@<delete> gmail.com)
" url    : http://d.hatena.ne.jp/ampmmn
"
" ----
" history
"	 0.0.6		2023-04-13	Migrate Python2 to 3.
"	 0.0.5		2015-10-20	Added autoload directory.
"	 0.0.4		2009-07-28	minor change
"	 0.0.3		2009-03-02	rename clmemogrep -> clmemogrep
"	 0.0.2		2009-02-23	add folding and header.
"	 0.0.1		2009-02-19	initial release.
" ----

if exists('loaded_clmemogrep') || &cp
  finish
endif
let loaded_clmemogrep=1

" Global Variables"{{{

" ChnageLogメモファイルのパス
if exists("g:clmemogrep_changelogfilepath") == 0
	let g:clmemogrep_changelogfilepath = './ChangeLog'
endif

" ChnageLogメモファイルの文字コード
if exists("g:clmemogrep_fileencoding") == 0
	let g:clmemogrep_fileencoding = &enc
endif

" itemの開始パターン(Python正規表現)
if exists("g:clmemogrep_startpattern") == 0
	let g:clmemogrep_startpattern = '^\s\*'
	" デフォルト設定は、1カラム目が空白で2カラム目がasteriskで始まる行
endif
" itemの終端パターン(Python正規表現)
if exists("g:clmemogrep_endpatern") == 0
	let g:clmemogrep_endpatern = '^($|\S)'
	" デフォルト設定は、空行または1カラム目から始まる行(=entry header)
endif

" 出力先ウインドウを検索する際のパターン
if exists("g:clmemogrep_outputwindow") == 0
	let g:clmemogrep_outputwindow = '^__ChangeLogMemoGrep$'
endif

" 出力ウインドウの位置
if exists("g:clmemogrep_Direction") == 0
	let g:clmemogrep_Direction = "rightbelow"
endif
if exists("g:clmemogrep_Split") == 0
	let g:clmemogrep_Split = ''
	"let g:clmemogrep_Split = 'v' で垂直分割
endif

" 出力ウインドウの高さ
if exists("g:clmemogrep_WindowHeight") == 0
	let g:clmemogrep_WindowHeight = 15
	" 0を指定した場合、現在のウインドウサイズの半分に分割します
endif

" 検索実行後、出力ウインドウにカーソルを移動するか?(0で元の状態を維持)
if exists("g:clmemogrep_setfocus") == 0
	let g:clmemogrep_setfocus=1
endif

" 折りたたみ表示にする
if exists("g:clmemogrep_fold") == 0
	let g:clmemogrep_fold=0
endif

" ヘッダを表示
if exists("g:clmemogrep_showheader") == 0
	let g:clmemogrep_showheader=1
endif

" 日付を表示
if exists("g:clmemogrep_showdate") == 0
	let g:clmemogrep_showdate=0
endif

" 結果ウインドウで<cr>を押したら、対応する位置にタグジャンプするようにする
" let g:clmemogrep_Jump=1

" アイテム間を句切る文字列(未定義の場合は間を置かずに出力)
"let g:clmemogrep_itemseparator="----------"


"}}} Global Variables

" Commands"{{{

" 検索
command! -nargs=* CLMemoGrep call clmemogrep#grep(expand(g:clmemogrep_changelogfilepath), 0, <f-args>)
" 検索 逆順表示
command! -nargs=* CLMemoGrepReverse call clmemogrep#grep(expand(g:clmemogrep_changelogfilepath), 1, <f-args>)

" 指定したキーワードを含むエントリの日付をカレンダー上に表示
command -nargs=* CLMemoCalendarSign call clmemogrep#calendarSign(expand(g:clmemogrep_changelogfilepath),1, <f-args>)

"}}}


" vim:foldmethod=marker

