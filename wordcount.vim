scriptencoding=utf-8

" .vimrcへの追加部分
" set statusline+=[wc:%{WordCount()}]
" set updatetime=500

" 以降は.vimrc等に追加するか、
" このままpluginフォルダへこのファイルをコピーします。
" WordCount() のパラメータを変更すると文字数ではなく、
" 単語数やバイト数を表示可能です。
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
  exec "silent normal g\<c-g>"
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
