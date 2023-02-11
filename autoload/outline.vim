vim9script

import "./outline/utils.vim" as utils

const ConfigWindowWidth = () => get(g:, "OutlineWidth", 40)
const ConfigWindowHeight = () => get(g:, "OutlineHeight", 10)
const ConfigOrientation = () => get(g:, "OutlineOrientation", "vertical")


const bufferName = "outline"
var orientation = ConfigOrientation()
var previousBufferNr = -1
var previousWinId = -1

const rules = {
  "ruby": [
    [ "describe '(.*)'.*$" ],
    [ "context '(.*)'.*$", "OutlineHighlight2" ],
    [ "it '(.*)'.*$", "OutlineHighlight1" ],
    [ 'def (.*)$', "OutlineHighlight1" ],
    [ 'class (.*)$', "OutlineHighlight2" ],
    [ 'module (.*)$', "OutlineHighlight2" ]
  ],
  "typescript.tsx": [
      [ '.*const([^=]*) \= \(.*\) \=\>.*$' ]
    ],
  "typescript": [
      [ '.*const([^=]*) \= \(.*\) \=\>.*$' ]
    ],
  "markdown": [
      [ '(# .*)$' ],
      [ '(## .*)$' ],
      [ '(### .*)$' ],
      [ '(#### .*)$' ],
      [ '(##### .*)$' ],
      [ '(###### .*)$' ]
    ],
}

const Build = (): list<any> => {
  const items = rules->get(&filetype, [])

  # Doing it with reduce does not work since for whatever reason the catch
  # from utils.FindMatches stops the reduce which occurs if no matching line
  # is found for the current item?!
  #return items
    #->reduce((result, item) => {
      #const matches = utils.FindMatches(item.pattern)
      #var lines = map(split(matches, "\n"), (_, x) => trim(x))

      #const entries = lines->mapnew((_, line) => ({
          #highlight: item.highlight,
          #lineNr: str2nr(line[0 : stridx(trim(line), " ") - 1]),
          #text: trim(line[stridx(trim(line), " ") :])
          #->substitute('\v' .. item.pattern, '\1', "g"),
          #indent: utils.GetIndent(line) }))

      #return result + entries
    #}, [])
    #->sort((a, b) => a.lineNr > b.lineNr ? 1 : -1)


  const view = winsaveview()
  var result = []
  for [pattern; rest] in items
    const highlight = rest->len() > 0 ? rest[0] : ""
    const matches = utils.FindMatches(pattern)
    var lines = map(split(matches, "\n"), (_, x) => trim(x))

    const entries = lines->mapnew((_, line) => ({
      highlight: highlight,
      lineNr: str2nr(line[0 : stridx(trim(line), " ") - 1]),
      text: trim(line[stridx(trim(line), " ") :])
        ->substitute('\v' .. pattern, '\1', "g"),
      indent: utils.GetIndent(line) }))

    result += entries
  endfor
  winrestview(view)

  return result->sort((a, b) => a.lineNr > b.lineNr ? 1 : -1)
}

export const Close = () => {
  var outlineBuffer = bufnr(bufferName)
  if outlineBuffer > 0 && bufexists(outlineBuffer)
    if previousWinId > 0
      win_gotoid(previousWinId)
    endif
    execute 'bwipeout! ' .. outlineBuffer
  endif
}

const SelectBufferLine = (lineNr: number) => {
  win_gotoid(previousWinId)
  execute 'silent buffer ' .. previousBufferNr
  setpos(".", [previousBufferNr, lineNr, 1])
}

const Select = () => {
  const props = prop_list(line("."))
  if len(props) == 0
    return
  endif

  Close()
  SelectBufferLine(props[0].id)
}

const Preview = () => {
  const props = prop_list(line("."))
  if len(props) == 0
    return
  endif

  const curWinId = win_getid()
  SelectBufferLine(props[0].id)
  win_gotoid(curWinId)
}

const ToggleOrientation = () => {
  if (bufname("%") != bufferName)
    return
  endif

  if orientation == "vertical"
    orientation = "horizontal"
    wincmd K
    wincmd J
    execute "resize " .. ConfigWindowHeight()
  else
    orientation = "vertical"
    wincmd H
    execute "vertical resize " .. ConfigWindowWidth()
  endif
}

const ToggleZoom = () => {
  if orientation == "vertical"
    if winwidth(0) > ConfigWindowWidth()
      execute("vertical resize " .. ConfigWindowWidth())
    else
      vertical resize
    endif
  else
    if winheight(0) > ConfigWindowHeight()
      execute("resize " .. ConfigWindowHeight())
    else
      resize
    endif
  endif
}

export const Open = () => {
  var outlineBuffer = bufnr(bufferName)
  if outlineBuffer > 0 && bufexists(outlineBuffer)
    return
  endif

  const previousLineNr = line(".")
  previousBufferNr = bufnr("%")
  previousWinId = win_getid()

  const outline = Build()

  if len(outline) == 0
    echohl ErrorMsg
    echo  "No matching rules found"
    echohl None
    return
  endif

  if orientation == "horizontal"
    new
    execute "resize " .. ConfigWindowHeight()
  else
    aboveleft vnew
    execute "vertical resize " .. ConfigWindowWidth()
  endif

  execute "file " .. bufferName
  setlocal filetype=outline

  const uniqueHighlights = outline
                      ->copy()
                      ->filter((_, item) => item.highlight->len() > 0)
                      ->map((_, item) => item.highlight)
                      ->sort()
                      ->uniq()

  for highlight in uniqueHighlights
    prop_type_add(highlight, { "highlight": highlight, "bufnr": bufnr(bufferName) })
  endfor

  var selectedOutlineLineNr = 1

  var lineNumber = 0
  for item in outline
    const line = repeat(" ", item.indent) .. item.text
    append(lineNumber, line)
    lineNumber += 1
    if item.highlight->len() > 0
      prop_add(lineNumber, 1, { length: strlen(line), type: item.highlight, id: item.lineNr })
    endif

    if item.lineNr == previousLineNr
      selectedOutlineLineNr = lineNumber
    endif
  endfor
  setlocal readonly nomodifiable

  setpos(".", [0, selectedOutlineLineNr, 1])

  nnoremap <script> <silent> <nowait> <buffer> <cr> <scriptcmd>Select()<cr>
  nnoremap <script> <silent> <nowait> <buffer> o <scriptcmd>Select()<cr>
  nnoremap <script> <silent> <nowait> <buffer> p <scriptcmd>Preview()<cr>
  nnoremap <script> <silent> <nowait> <buffer> m <scriptcmd>ToggleOrientation()<cr>
  nnoremap <script> <silent> <nowait> <buffer> z <scriptcmd>ToggleZoom()<cr>
}

export const Toggle = () => {
  var outlineBuffer = bufnr(bufferName)
  if outlineBuffer > 0 && bufexists(outlineBuffer)
    Close()
  else
    Open()
  endif
}
