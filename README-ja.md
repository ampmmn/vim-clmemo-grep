# vim-clmemo-grep

[README in English](README.md)

## 概要

ChangeLogメモを検索するためのVimプラグイン

ChangeLogメモについては  http://0xcc.net/unimag/1/ を参照のこと

ChangeLogメモと呼ぶ単一のテキストファイルをキーワード検索し、結果を記事単位で検索することができる。  
下記のような動作

![](image/intro.gif)

## 使い方

### インストール

普通のVimプラグインのように、`~/.vim`(Windows環境なら`~/vimfiles`)に配置する。

### コマンド

プラグインをインストールすると、下記のコマンドが使えるようになる。

`CLMemoGrep` / `CLMemoGrepReverse` / `CLMemoCalendarSign`

- `CLMemoGrep`
  -  指定したキーワードでChangeLogメモファイルの検索を行う。検索結果を専用のウインドウに表示する
```
:CLMemoGrep keyword1 keyword2 ...
```

- `CLMemoGrepReverse`
    `CLMemoGrep`の結果を逆順に表示する。
```
:CLMemoGrepReverse keyword1 keyword2 ...
```

- `CLMemoCalendarSign`
  -  `[calendar-vim](https://github.com/mattn/calendar-vim) が入っている場合は、検索にヒットした記事が存在する日付をカレンダー上で強調表示する。

```
:CLMemoGrepCalendarSign keyword1 keyword2 ...
```

![](image/sign.png)
- 記事が存在する日付に「@」が付く

### ほか

[calendar-vim](https://github.com/mattn/calendar-vim)を使っている場合、下記を定義しておくと、カレンダーの日付をクリックすると、ChangeLogメモの当該日付にジャンプできる

```
let g:calendar_action='CalendarActionCLMemo'
```

### 変数

- `g:clmemogrep_changelogfilepath`
  - ChangeLogメモのファイルパスを指定する

- `g:clmemogrep_fileencoding`
  - ChangeLogメモのエンコーディングを指定する(指定がない場合は`&enc`と同じとみなす)

- `g:clmemogrep_setfocus` (1 or 0)
  - 検索を実行したときフォーカスを結果ウインドウに移動するかどうかを指定する

- `g:clmemogrep_fold` (1 or 0)
  - 検索結果ウインドウに表示する結果を折りたたむ(fold)するかどうかを指定する

- `g:clmemogrep_showheader` (1 or 0)
  - 検索結果ウインドウに検索結果の件数を表示するかどうかを指定する

- `g:clmemogrep_showdate` (1 or 0)
  - 検索結果に記事の日付を表示するかどうかを指定する

- `g:clmemogrep_Split`
  - 検索結果ウインドウの分割方法を指定する
    - '' : 水平分割
    - `v' : 垂直分割

## 必要なもの

- Vimは`+python3/dyn' が有効であること
- VimからPython3が使えるようになっていること


