function! FindMatches(pattern)
  try
    return execute('g/\v^\s*' . a:pattern . '.*$/')
  catch
    return ""
  endtry
endfunction

function! IndentFromResult(line)
  return match(get(a:line, stridx(trim(a:line), " ")+1, ":"), "[^ ]")
endfunction

function! LineNrFromResult(line)
  return str2nr(get(a:line, 0, stridx(trim(a:line), " ")-1))
endfunction

function! TextFromResult(line)
  return get(a:line, stridx(trim(a:line), " ")+1, ":")
endfunction

function! ReplaceWithFirstGroup(text, pattern)
  return substitute(a:text, '\v^\s*' . a:pattern . '.*$', '\1', "g")
endfunction

function! MergeRules(baseRules, additionalRules)
  let allRules = extendnew({}, s:baseRules)

  for [ft, patterns] in items(a:additionalRules)
    let existingFtPatterns = get(allRules, ft, [])

    if len(existingFtPatterns) > 0
      let allRules[ft] = existingFtPatterns + patterns
    else
      let allRules[ft] = patterns
    endif
  endfor

  return allRules
endfunction

