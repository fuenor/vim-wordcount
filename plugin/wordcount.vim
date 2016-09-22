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
" 以下を.vimrcに追加すると、ステータスラインで「純粋な文字数」のリアルタイ
" ム表示を行うことができます。
" set statusline+=[wc:%{WordCount()}]
" set updatetime=500
"
" カウント方法は以下のように指定します
" char : 文字数
" word : 単語数
" byte : バイト数
if !exists('wordcount_type')
  let wordcount_type = 'char'
endif

" 表示方法は以下のように指定します
" long  : [現在位置(または選択)文字数/総文字数]
" short : 総文字数/選択文字数の自動切替
if !exists('wordcount_display')
  let wordcount_display = 'long'
endif

" g<C-g>の文字数を「純粋な文字数」に置き換えます。
nmap g<C-g> <Plug>(WordCount)
vmap g<C-g> <Plug>(WordCount)

augroup WordCount
  autocmd!
  autocmd BufRead,BufEnter,CursorHold * call WordCount(wordcount_type)
  autocmd CursorMoved * call s:CursorMoved(wordcount_type)
augroup END

function! s:CursorMoved(type)
  if mode() !~ "[vV\<C-v>]"
    return
  endif
  call WordCount(a:type)
endfunction

let s:wc_status = ''
let s:WordCountStr = ''
let s:wc_idx = 'char'
let s:WordCountDict = {'word': 2, 'char': 3, 'byte': 4}
let s:VisualWordCountDict = {'word': 1, 'char': 2, 'byte': 3}
function! WordCount(...)
  if a:0 == 0
    return s:WordCountStr
  endif

  let s:wc_idx = a:1
  " g<c-g>の何番目の要素を読むか
  let cidx = 3
  let mode = mode()
  " 選択モードと行選択モードの場合はwordcountdictの値を-1することで合わせる
  " 矩形選択モードでこの調整は不要
  if mode =~ "^[vV]"
    silent! let cidx = s:VisualWordCountDict[a:1]
  else
    silent! let cidx = s:WordCountDict[a:1]
  endif

  " g<c-g>の結果をパースする
  let s:WordCountStr = ''
  let v:statusmsg=''
  let saved_status = v:statusmsg
  exec "silent normal! g\<c-g>"
  let statusmsg = v:statusmsg
  let v:statusmsg = saved_status
  if statusmsg !~ '^--'
    let msg = split(statusmsg, ';')
    let str = msg[cidx < len(msg) ? cidx : len(msg)-1]
    let cur = str2nr(matchstr(str,'\s\d\+', 0, 1))
    let end = str2nr(matchstr(str,'\s\d\+', 0, 2))
    " ここで(改行コード数*改行コードサイズ)を'g<C-g>'の文字数から引く
    let cr = &ff == 'dos' ? 2 : 1
    if a:1 == 'char' && mode == "n"
      " ノーマルモードの場合は1行目からの行数として改行文字の数を得る
      let cur -= cr * (line('.') - 1)
      let end -= cr * line('$')
      " 改行をカウントしないので最終行が空行だとオーバーすることがある
      let cur = cur > end ? end : cur
    elseif a:1 == 'char' && mode =~ "^[vV]"
      " 選択モード,行選択モードならば，g-<C-g>にある 選択 より改行文字の数を得る
      " 矩形選択ではこの処理はしない
      silent! let str = msg[0]
      let vcur = str2nr(matchstr(str,'\s\d\+', 0, 1)) -1
      let vcur += mode =~ '\CV' ? 1 : 0
      let vend = str2nr(matchstr(str,'\s\d\+', 0, 2)) -1
      " ここで(改行コード数*改行コードサイズ)を'g<C-g>'の文字数から引く
      let cur -= cr * (vcur)
      let end -= cr * (vend+1)
    elseif a:1 == 'char' && mode =~ "\<C-v>"
      let end -= cr * line('$')
    endif
    let altstr = substitute(str, '\d*\d\+\(\D\+\)\d\d*', cur.'\1'.end, '')
    let s:wc_status = substitute(statusmsg, str, altstr, '')
    let s:WordCountStr = g:wordcount_display == 'long' ? printf('%d/%d', cur, end) : (mode == 'n' ? end : cur)
  endif
  if mode =~ "^[vV]" && has('gui_running')
    echo
  endif
  return s:WordCountStr
endfunction

nmap <silent> <Plug>(WordCount) :<C-U>call <SID>altcmd('n')<CR>
vmap <silent> <Plug>(WordCount) :<C-U>call <SID>altcmd('v')<CR>

function! s:altcmd(mode)
  let saved_status = v:statusmsg
  silent! exe "normal! g\<c-g>"
  let statusmsg = v:statusmsg
  let v:statusmsg = saved_status
  if statusmsg =~ '^--'
    echom statusmsg
    return
  endif
  if a:mode =~ 'n'
    doau WordCount CursorHold
    echom s:wc_status
  else
    let msg = split(statusmsg, ';')
    let cidx = s:VisualWordCountDict[g:wordcount_type]+1
    let str = msg[cidx < len(msg) ? cidx : len(msg)-1]
    let num = split(s:WordCountStr, '/')
    if g:wordcount_display == 'short'
      echom substitute(str, '\d*\d\+\(\D\+\)\d\d*', num[0], '')
    else
      echom substitute(str, '\d*\d\+\(\D\+\)\d\d*', num[0].'\1'.num[1], '')
    endif
  endif
endfunction

