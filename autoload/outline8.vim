let s:ConfigWindowWidth = get(g:, "OutlineWidth", 40)
let s:ConfigWindowHeight = get(g:, "OutlineHeight", 10)
let s:ConfigOrientation = get(g:, "OutlineOrientation", "vertical")
let s:ConfigIncludeBaseRules = get(g:, "OutlineIncludeBaseRules", true)
let s:ConfigRules = get(g:, "OutlineRules", {})

let s:bufferName = "outline"
let s:noHighlight = "no-highlight"
let s:orientation = s:ConfigOrientation
let s:previousBufferNr = -1
let s:previousWinId = -1

" TODO More included highlight groups (and better names...)

" Note: I removed 'export' qualifier from rules because it doesn't exist in classic vimscript. If you want these rules to be available globally, you could use g:rules instead of s:rules
let s:rules = {
\   "ruby": [
\     ["describe '(.*)'"],
\     ["context '(.*)'", "OutlineHighlight2"],
\     ["it '(.*)'", "OutlineHighlight1"],
\     ['def ([^\(]*)', "OutlineHighlight1"],
\     ['class (.*)', "OutlineHighlight2"],
\     ['module (.*)', "OutlineHighlight2"]
\   ],
\   "typescript.tsx": [
\     ['.*const ([^=]*) \= \(.*\) \=\>'],
\     ['.*interface (.*)\s*\{', "OutlineHighlight2"],
\     ['.*type (.*)\s*\=', "OutlineHighlight2"],
\     ["describe\\([\"'](.*)[\"'],"],
\     ["it\\([\"'](.*)[\"'],", "OutlineHighlight1"]
\   ],
\   "typescript": [
\     ['.*const ([^=]*) \= \(.*\) \=\>'],
\     ['.*interface (.*)\s*\{', "OutlineHighlight2"],
\     ['.*type (.*)\s*\=', "OutlineHighlight2"],
\     ["describe\\([\"'](.*)[\"'],"],
\     ["it\\([\"'](.*)[\"'],", "OutlineHighlight1"]
\   ],
\   "markdown": [
\     ['(# .*)'],
\     ['(## .*)'],
\     ['(### .*)'],
\     ['(#### .*)'],
\     ['(##### .*)'],
\     ['(###### .*)']
\   ],
\}

function! Build()
  let rules = s:MergeRules(s:ConfigIncludeBaseRules ? s:rules : {}, s:ConfigRules)
  let items = get(rules, &filetype, [])

  let view = winsaveview()
  let result = []
  for [pattern; rest] in items
    let highlight = len(rest) > 0 ? rest[0] : noHighlight
    let matches = s:FindMatches(pattern)
    let lines = map(split(matches, "\n"), 'v:val')

    let entries = map(lines, '{ "highlight": v:val, "lineNr": LineNrFromResult(v:val), "text": ReplaceWithFirstGroup(TextFromResult(v:val), pattern), "indent": IndentFromResult(v:val) }')

    let result = result + entries
  endfor
  call winrestview(view)

  return sort(result, 'v:val.lineNr > v:val.lineNr ? 1 : -1')
endfunction

function! Close()
  let outlineBuffer = bufnr(s:bufferName)
  if outlineBuffer > 0 && bufexists(outlineBuffer)
    if s:previousWinId > 0
      call win_gotoid(previousWinId)
    endif
    execute 'bwipeout! ' . outlineBuffer
  endif
endfunction

function! SelectBufferLine(lineNr)
  call win_gotoid(s:previousWinId)
  execute 'silent buffer ' . s:previousBufferNr
  call setpos(".", [0, a:lineNr, 1, 0])
  normal! zz
endfunction

function! Select()
  let props = prop_list(line("."))
  if len(props) == 0
    return
  endif

  call Close()
  call SelectBufferLine(props[0].id)
endfunction

function! Preview()
  let props = prop_list(line("."))
  if len(props) == 0
    return
  endif

  let curWinId = win_getid()
  call SelectBufferLine(props[0].id)
  call win_gotoid(curWinId)
endfunction

function! ToggleOrientation()
  if bufname("%") != s:bufferName
    return
  endif

  if s:orientation == "vertical"
    let s:orientation = "horizontal"
    wincmd K
    wincmd J
    execute "resize " .. s:ConfigWindowHeight
  else
    let s:orientation = "vertical"
    wincmd H
    execute "vertical resize " .. s:ConfigWindowWidth
  endif
endfunction

function! ToggleZoom()
  if s:orientation == "vertical"
    if winwidth(0) > s:ConfigWindowWidth
      execute "vertical resize " .. s:ConfigWindowWidth
    else
      vertical resize
    endif
  else
    if winheight(0) > s:ConfigWindowHeight
      execute "resize " .. s:ConfigWindowHeight
    else
      resize
    endif
  endif
endfunction

function! Open()
  let outlineBuffer = bufnr(s:bufferName)
  if outlineBuffer > 0 && bufexists(outlineBuffer)
    return
  endif

  let previousLineNr = line(".")
  let s:previousBufferNr = bufnr("%")
  let s:previousWinId = win_getid()

  let outline = Build()

  if len(outline) == 0

    echohl ErrorMsg
    echo "No matching rules found"
    echohl None
    return
  endif

  if s:orientation == "horizontal"
    new
    execute "resize " .. s:ConfigWindowHeight
  else
    aboveleft vnew
    execute "vertical resize " .. s:ConfigWindowWidth
  endif

  execute "file " .. s:bufferName
  setlocal filetype=outline

  let uniqueHighlights = uniq(sort(map(copy(outline), '"v:val.highlight"')))

  for highlight in uniqueHighlights
    if highlight == s:noHighlight
      call prop_type_add(noHighlight, { "bufnr": bufnr(s:bufferName) })
    else
      call prop_type_add(highlight, { "highlight": highlight, "bufnr": bufnr(s:bufferName) })
    endif
  endfor

  let selectedOutlineLineNr = 1

  for i in range(len(outline))

    let item = outline[i]
    let line = repeat(" ", item.indent) .. item.text
    call append(i, line)
    call prop_add(i+1, 1, { "length": len(line), "type": item.highlight, "id": item.lineNr})

    if item.lineNr == previousLineNr
      let selectedOutlineLineNr = i+1
    endif
  endfor
  setlocal readonly nomodifiable

  call setpos(".", [0, selectedOutlineLineNr, 1, 0])

  nnoremap <buffer> <CR> :call Select()<CR>
  nnoremap <buffer> o :call Select()<CR>
  nnoremap <buffer> p :call Preview()<CR>
  nnoremap <buffer> m :call ToggleOrientation()<CR>
  nnoremap <buffer> z :call ToggleZoom()<CR>
endfunction


function! Toggle()
  let outlineBuffer = bufnr(s:bufferName)
  if outlineBuffer > 0 && bufexists(outlineBuffer)
    call Close()
  else
    call Open()
  endif
endfunction
