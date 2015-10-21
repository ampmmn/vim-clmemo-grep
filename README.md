vim-clmemo-grep
==============

Description
-----------
A vim plugin for grepping 'Changelog Memo'.
Changelog Memo is a kind of concept that writting memo into one text file.
For more details, see http://0xcc.net/unimag/1/ (written in Japanese).

Installation
------------
Installation is as well as other usual plugins.
Download zip file on github, expand it and place ~/.vim or ~/vimfiles.

Usage
-----------
Once this installation is done, you can use the following commands.

CLMemoGrep / CLMemoGrepReverse / CLMemoCalendarSign

CLMemoGrep: searchs for the given words in the 'Changelog Memo' file.

    :CLMemoGrep keyword1 keyword2 ...

CLMemoGrepReverse : is same as CLMemoGrep. But the result is listed in resersed order.

    :CLMemoGrepReverse keyword1 keyword2 ...

CLMemoCalendarSign : is same as CLMemoGrep too. And the result is marked on the calendar if calendar-vim is installed.
(calenar-vim is available https://github.com/mattn/calendar-vim .)

    :CLMemoGrepCalendarSign keyword1 keyword2 ...

Variables
------------
g:clmemogrep_changelogfilepath : specifies file path of the chanegLog memo.

g:clmemogrep_fileencoding : specifies encoding of the changelog memo.

Requirements
------------
'+python' feature is needed to use this plugin.


