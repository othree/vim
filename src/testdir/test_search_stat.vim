" Tests for search_stats, when "S" is not in 'shortmess'

source check.vim
source screendump.vim

func Test_search_stat()
  new
  set shortmess-=S
  " Append 50 lines with text to search for, "foobar" appears 20 times
  call append(0, repeat(['foobar', 'foo', 'fooooobar', 'foba', 'foobar'], 10))

  " match at second line
  call cursor(1, 1)
  let messages_before = execute('messages')
  let @/ = 'fo*\(bar\?\)\?'
  let g:a = execute(':unsilent :norm! n')
  let stat = '\[2/50\]'
  let pat = escape(@/, '()*?'). '\s\+'
  call assert_match(pat .. stat, g:a)
  " didn't get added to message history
  call assert_equal(messages_before, execute('messages'))

  " Match at last line
  call cursor(line('$')-2, 1)
  let g:a = execute(':unsilent :norm! n')
  let stat = '\[50/50\]'
  call assert_match(pat .. stat, g:a)

  " No search stat
  set shortmess+=S
  call cursor(1, 1)
  let stat = '\[2/50\]'
  let g:a = execute(':unsilent :norm! n')
  call assert_notmatch(pat .. stat, g:a)
  set shortmess-=S

  " Many matches
  call cursor(line('$')-2, 1)
  let @/ = '.'
  let pat = escape(@/, '()*?'). '\s\+'
  let g:a = execute(':unsilent :norm! n')
  let stat = '\[>99/>99\]'
  call assert_match(pat .. stat, g:a)
  call cursor(line('$'), 1)
  let g:a = execute(':unsilent :norm! n')
  let stat = 'W \[1/>99\]'
  call assert_match(pat .. stat, g:a)

  " Many matches
  call cursor(1, 1)
  let g:a = execute(':unsilent :norm! n')
  let stat = '\[2/>99\]'
  call assert_match(pat .. stat, g:a)
  call cursor(1, 1)
  let g:a = execute(':unsilent :norm! N')
  let stat = 'W \[>99/>99\]'
  call assert_match(pat .. stat, g:a)

  " right-left
  if exists("+rightleft")
    set rl
    call cursor(1,1)
    let @/ = 'foobar'
    let pat = 'raboof/\s\+'
    let g:a = execute(':unsilent :norm! n')
    let stat = '\[20/2\]'
    call assert_match(pat .. stat, g:a)
    set norl
  endif

  " right-left bottom
  if exists("+rightleft")
    set rl
    call cursor('$',1)
    let pat = 'raboof?\s\+'
    let g:a = execute(':unsilent :norm! N')
    let stat = '\[20/20\]'
    call assert_match(pat .. stat, g:a)
    set norl
  endif

  " right-left back at top
  if exists("+rightleft")
    set rl
    call cursor('$',1)
    let pat = 'raboof/\s\+'
    let g:a = execute(':unsilent :norm! n')
    let stat = 'W \[20/1\]'
    call assert_match(pat .. stat, g:a)
    call assert_match('search hit BOTTOM, continuing at TOP', g:a)
    set norl
  endif

  " normal, back at bottom
  call cursor(1,1)
  let @/ = 'foobar'
  let pat = '?foobar\s\+'
  let g:a = execute(':unsilent :norm! N')
  let stat = 'W \[20/20\]'
  call assert_match(pat .. stat, g:a)
  call assert_match('search hit TOP, continuing at BOTTOM', g:a)
  call assert_match('W \[20/20\]', Screenline(&lines))

  " normal, no match
  call cursor(1,1)
  let @/ = 'zzzzzz'
  let g:a = ''
  try
    let g:a = execute(':unsilent :norm! n')
  catch /^Vim\%((\a\+)\)\=:E486/
    let stat = ''
    " error message is not redir'ed to g:a, it is empty
    call assert_true(empty(g:a))
  catch
    call assert_false(1)
  endtry

  " with count
  call cursor(1, 1)
  let @/ = 'fo*\(bar\?\)\?'
  let g:a = execute(':unsilent :norm! 2n')
  let stat = '\[3/50\]'
  let pat = escape(@/, '()*?'). '\s\+'
  call assert_match(pat .. stat, g:a)
  let g:a = execute(':unsilent :norm! 2n')
  let stat = '\[5/50\]'
  call assert_match(pat .. stat, g:a)

  " with offset
  call cursor(1, 1)
  call feedkeys("/fo*\\(bar\\?\\)\\?/+1\<cr>", 'tx')
  let g:a = execute(':unsilent :norm! n')
  let stat = '\[5/50\]'
  let pat = escape(@/ .. '/+1', '()*?'). '\s\+'
  call assert_match(pat .. stat, g:a)

  " normal, n comes from a mapping
  "     Need to move over more than 64 lines to trigger char_avail(.
  nnoremap n nzv
  call cursor(1,1)
  call append(50, repeat(['foobar', 'foo', 'fooooobar', 'foba', 'foobar'], 10))
  call setline(2, 'find this')
  call setline(70, 'find this')
  let @/ = 'find this'
  let pat = '/find this\s\+'
  let g:a = execute(':unsilent :norm n')
  " g:a will contain several lines
  let g:b = split(g:a, "\n")[-1]
  let stat = '\[1/2\]'
  call assert_match(pat .. stat, g:b)
  unmap n

  " normal, but silent
  call cursor(1,1)
  let @/ = 'find this'
  let pat = '/find this\s\+'
  let g:a = execute(':norm! n')
  let stat = '\[1/2\]'
  call assert_notmatch(pat .. stat, g:a)

  " normal, n comes from a silent mapping
  " First test a normal mapping, then a silent mapping
  call cursor(1,1)
  nnoremap n n
  let @/ = 'find this'
  let pat = '/find this\s\+'
  let g:a = execute(':unsilent :norm n')
  let g:b = split(g:a, "\n")[-1]
  let stat = '\[1/2\]'
  call assert_match(pat .. stat, g:b)
  nnoremap <silent> n n
  call cursor(1,1)
  let g:a = execute(':unsilent :norm n')
  let g:b = split(g:a, "\n")[-1]
  let stat = '\[1/2\]'
  call assert_notmatch(pat .. stat, g:b)
  call assert_match(stat, g:b)
  " Test that the message is not truncated
  " it would insert '...' into the output.
  call assert_match('^\s\+' .. stat, g:b)
  unmap n

  " Clean up
  set shortmess+=S
  " close the window
  bwipe!
endfunc

func! Test_search_stat_screendump()
  CheckScreendump

  let lines =<< trim END
    set shortmess-=S
    " Append 50 lines with text to search for, "foobar" appears 20 times
    call append(0, repeat(['foobar', 'foo', 'fooooobar', 'foba', 'foobar'], 20))
    call setline(2, 'find this')
    call setline(70, 'find this')
    nnoremap n n
    let @/ = 'find this'
    call cursor(1,1)
    norm n
  END
  call writefile(lines, 'Xsearchstat')
  let buf = RunVimInTerminal('-S Xsearchstat', #{rows: 10})
  call term_wait(buf)
  call VerifyScreenDump(buf, 'Test_searchstat_1', {})

  call term_sendkeys(buf, ":nnoremap <silent> n n\<cr>")
  call term_sendkeys(buf, "gg0n")
  call term_wait(buf)
  call VerifyScreenDump(buf, 'Test_searchstat_2', {})

  call StopVimInTerminal(buf)
  call delete('Xsearchstat')
endfunc
