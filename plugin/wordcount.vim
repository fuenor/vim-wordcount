scriptencoding=utf-8
let g:loaded_wordcount = 1

" wordcount.vimは現在開いているバッファの「純粋な文字数」を表示するプラグイン
" です。
"
" 内部的には`g<C-g>`コマンドを利用していますが、改行コードの違いによって表示さ
" れる文字数が変化してしまう`g<C-g>`と違い、改行自体を含まない「純粋な文字数」
" をカウントすることができます。
" (`g<C-g>`はWindowsのCR+LFを2文字としてカウントしてしまいます)
"
" wordcount.vimを有効にするには、以降を.vimrc等に追加するか、pluginフォルダへ
" このファイル自体をコピーします。
"
" また以下を.vimrcに追加すると、ステータスラインで「純粋な文字数」のリアルタイ
" ム表示を行うことができます。
" set statusline+=[wc:%{WordCount()}]
" set updatetime=500

" autocmd で使用されているWordCount('char') のパラメータを変更すると文字数では
" なく、単語数やバイト数を表示可能です。
"
" :call WordCount('char') " count char
" :call WordCount('byte') " count byte
" :call WordCount('word') " count word

augroup WordCount
  autocmd!
  autocmd BufWinEnter,CursorHold,CursorMoved * call WordCount('char')
augroup END

let s:WordCountStr = ''
let s:WordCountDict = {'word': 2, 'char': 3, 'byte': 4}
let s:VisualWordCountDict = {'word': 1, 'char': 2, 'byte': 3}
function! WordCount(...)
  if a:0 == 0
    return s:WordCountStr
  endif
  " g<c-g>の何番目の要素を読むか
  let cidx = 3
  " 選択モードと行選択モードの場合はwordcountdictの値を-1することで合わせる
  " 矩形選択モードでこの調整は不要
  if mode() =~ "^v"
    silent! let cidx = s:VisualWordCountDict[a:1]
  else
    silent! let cidx = s:WordCountDict[a:1]
  endif

  " g<c-g>の結果をパースする
  let s:WordCountStr = ''
  let s:saved_status = v:statusmsg
  exec "silent normal! g\<c-g>"
  if v:statusmsg !~ '^--'
    let str = ''
    silent! let str = split(v:statusmsg, ';')[cidx]
    let cur = str2nr(matchstr(str,'\s\d\+',0,1))
    let end = str2nr(matchstr(str,'\s\d\+',0,2))
    " ここで(改行コード数*改行コードサイズ)を'g<C-g>'の文字数から引く
    if a:1 == 'char' && mode() == "n"
      " ノーマルモードの場合は1行目からの行数として改行文字の数を得る
      let cr = &ff == 'dos' ? 2 : 1
      let cur -= cr * (line('.') - 1)
      let end -= cr * line('$')
    elseif a:1 == 'char' && mode() =~ "^v"
      " 選択モード,行選択モードならば，g-<C-g>にある 選択 より改行文字の数を得る
      " 矩形選択ではこの処理はしない
      silent! let str = split(v:statusmsg, ';')[0]
      let vcur = str2nr(matchstr(str,'\s\d\+',0,1)) -1
      let vend = str2nr(matchstr(str,'\s\d\+',0,2)) -1
      " ここで(改行コード数*改行コードサイズ)を'g<C-g>'の文字数から引く
      let cr = &ff == 'dos' ? 2 : 1
      let cur -= cr * vcur
      let end -= cr * vend
    endif
    let s:WordCountStr = printf('%d/%d', cur, end)
  endif
  let v:statusmsg = s:saved_status
  return s:WordCountStr
endfunction
