scriptencoding=utf-8

" word-count.vimは現在開いているバッファの文字数をリアルタイムにステータス行へ
" 表示するプラグインです。
" 内部的には`g<C-g>`コマンドを利用していますが、改行コードの違いによって文字数
" が変化してしまう`g<C-g>`と違い、純粋な文字数をカウントすることができます。
"
" 以下を.vimrcへ追加してください。
" set statusline+=[wc:%{WordCount()}]
" set updatetime=500

" 以降は.vimrc等に追加するか、pluginフォルダへこのファイル自体をコピーします。
" autocmd で使用されているWordCount('char') のパラメータを変更すると文字数では
" なく、単語数やバイト数を表示可能です。
" 文字数は改行を除いた純粋な文字数になります。
"
" :call WordCount('char') " count char
" :call WordCount('byte') " count byte
" :call WordCount('word') " count word

augroup WordCount
  autocmd!
  autocmd BufWinEnter,InsertLeave,CursorHold * call WordCount('char')
augroup END

let s:WordCountStr = ''
let s:WordCountDict = {'word': 2, 'char': 3, 'byte': 4}
function! WordCount(...)
  if a:0 == 0
    return s:WordCountStr
  endif
  let cidx = 3
  silent! let cidx = s:WordCountDict[a:1]

  let s:WordCountStr = ''
  let s:saved_status = v:statusmsg
  exec "silent normal! g\<c-g>"
  if v:statusmsg !~ '^--'
    let str = ''
    silent! let str = split(v:statusmsg, ';')[cidx]
    let cur = str2nr(matchstr(str, '\d\+'))
    let end = str2nr(matchstr(str, '\d\+\s*$'))
    if a:1 == 'char'
      " ここで(改行コード数*改行コードサイズ)を'g<C-g>'の文字数から引く
      let cr = &ff == 'dos' ? 2 : 1
      let cur -= cr * (line('.') - 1)
      let end -= cr * line('$')
    endif
    let s:WordCountStr = printf('%d/%d', cur, end)
  endif
  let v:statusmsg = s:saved_status
  return s:WordCountStr
endfunction
