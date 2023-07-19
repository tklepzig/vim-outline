vim9script

import "./utils.vim" as utils

const ConfigWindowWidth = () => get(g:, "OutlineWidth", 40)
const ConfigWindowHeight = () => get(g:, "OutlineHeight", 10)
const ConfigOrientation = () => get(g:, "OutlineOrientation", "vertical")
const ConfigIncludeBaseRules = () => get(g:, "OutlineIncludeBaseRules", true)
const ConfigRules = () => get(g:, "OutlineRules", {})

const bufferName = "outline"
const noHighlight = "no-highlight"
var orientation = ConfigOrientation()
var previousBufferNr = -1
var previousWinId = -1
var currentCollectionName = ""

# TODO More included highlight groups (and better names...)

const g:rules = {
  "ruby": {
      "RSpec": [
        [ "describe '(.*)'" ],
        [ "context '(.*)'", "OutlineHighlight2" ],
        [ "it '(.*)'", "OutlineHighlight1" ],
      ],
      "Ruby": [
        [ 'def ([^\(]*)', "OutlineHighlight1" ],
        [ 'class (.*)', "OutlineHighlight2" ],
        [ 'module (.*)', "OutlineHighlight2" ],
      ],
  }
}

# TODO Edit/Add collections live into an editable pane? (E.g. switch via
# mapping between collection editor and search result view)
const CollectionNames = (): list<string> => {
  const rules = utils.MergeRules(ConfigIncludeBaseRules() ? g:rules : {}, ConfigRules())
  return rules->get(&filetype, {})->keys()
}

def CollectionItems(collectionName: string): list<any>
  const collections = utils.MergeRules(ConfigIncludeBaseRules() ? g:rules : {}, ConfigRules())->get(&filetype, {})

  if collectionName != ""
    currentCollectionName = collectionName
    return collections->get(collectionName, [])
  endif

  const collectionsItems = collections->items()
  if collectionsItems->len() > 0
    const [name, items] = collectionsItems[0]
    currentCollectionName = name
    return items
  endif

  return []
enddef

const Build = (collectionName: string): list<any> => {
  const items = CollectionItems(collectionName)

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
    const highlight = rest->len() > 0 ? rest[0] : noHighlight
    const matches = utils.FindMatches(pattern)
    var lines = map(split(matches, "\n"), (_, x) => trim(x))

    const entries = lines->mapnew((_, line) => ({
      highlight: highlight,
      lineNr: utils.LineNrFromResult(line),
      text: utils.ReplaceWithFirstGroup(utils.TextFromResult(line), pattern),
      indent: utils.IndentFromResult(line) }))

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
      previousWinId = -1
    endif
    execute 'bwipeout! ' .. outlineBuffer
  endif
}

const SelectBufferLine = (lineNr: number) => {
  win_gotoid(previousWinId)
  execute 'silent buffer ' .. previousBufferNr
  setpos(".", [previousBufferNr, lineNr, 1])
  normal zz
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

export const CreateWindow = () => {
  if orientation == "horizontal"
    new
    execute "resize " .. ConfigWindowHeight()
  else
    aboveleft vnew
    execute "vertical resize " .. ConfigWindowWidth()
  endif

  execute "silent file " .. bufferName
  setlocal filetype=outline
}

export const FreezeWindow = () => {
  setlocal readonly nomodifiable
}

export const OpenCollectionsView = () => {
  Close()

  const collectionNames = CollectionNames()

  CreateWindow()

  var lineNumber = 0
  for name in collectionNames
    append(lineNumber, name)
    lineNumber += 1
  endfor

  append(lineNumber, "Custom (WIP)")
  lineNumber += 1

  FreezeWindow()
  setpos(".", [0, 1, 1])

  nnoremap <script> <silent> <nowait> <buffer> <cr> <scriptcmd>SelectCollection()<cr>
  nnoremap <script> <silent> <nowait> <buffer> o <scriptcmd>SelectCollection()<cr>
}

export const OpenResultView = (collectionName: string) => {
  Close()

  const previousLineNr = line(".")
  previousBufferNr = bufnr("%")
  previousWinId = win_getid()

  const outline = Build(collectionName)

  CreateWindow()

  const uniqueHighlights = outline
                      ->mapnew((_, item) => item.highlight)
                      ->sort()
                      ->uniq()

  for highlight in uniqueHighlights
    if highlight == noHighlight
      prop_type_add(noHighlight, { "bufnr": bufnr(bufferName) })
    else
      prop_type_add(highlight, { "highlight": highlight, "bufnr": bufnr(bufferName) })
    endif
  endfor

  var selectedOutlineLineNr = 1
  var lineNumber = 0
  append(lineNumber, "Collection: " .. currentCollectionName)
  lineNumber += 2

  for item in outline
    const line = repeat(" ", item.indent) .. item.text
    append(lineNumber, line)
    lineNumber += 1
    prop_add(lineNumber, 1, { length: strlen(line), type: item.highlight, id: item.lineNr })

    if item.lineNr == previousLineNr
      selectedOutlineLineNr = lineNumber
    endif
  endfor

  FreezeWindow()
  setpos(".", [0, selectedOutlineLineNr, 1])

  nnoremap <script> <silent> <nowait> <buffer> <cr> <scriptcmd>Select()<cr>
  nnoremap <script> <silent> <nowait> <buffer> o <scriptcmd>Select()<cr>
  nnoremap <script> <silent> <nowait> <buffer> p <scriptcmd>Preview()<cr>
  nnoremap <script> <silent> <nowait> <buffer> m <scriptcmd>ToggleOrientation()<cr>
  nnoremap <script> <silent> <nowait> <buffer> z <scriptcmd>ToggleZoom()<cr>
  nnoremap <script> <silent> <nowait> <buffer> c <scriptcmd>OpenCollectionsView()<cr>
}

const SelectCollection = () => {
  const line = getline(".")
  if (line != "Custom (WIP)")
    OpenResultView(getline("."))
  endif
}


export const Toggle = () => {
  var outlineBuffer = bufnr(bufferName)
  if outlineBuffer > 0 && bufexists(outlineBuffer)
    Close()
  else
    OpenResultView(currentCollectionName)
  endif
}
