vim9script

export const GetIndent = (line): number => 
  match(line[stridx(trim(line), " ") :], "[^ ]")

export const FindMatches = (pattern: string): string => {
  try
    return execute('g/\v^\s*' .. pattern .. '.*$')
  catch
    return ""
  endtry
}

export const LineNrFromResult = (line: string): number => {
  return str2nr(line[0 : stridx(trim(line), " ") - 1])
}

export const TextFromResult = (line: string): string => {
  return line[stridx(trim(line), " ") :]
}

export const ReplaceWithFirstGroup = (text: string, pattern: string): string => {
  return text->substitute('\v^\s*' .. pattern .. '.*$', '\1', "g")
}

export const MergeRules = (baseRules: dict<any>, additionalRules): dict<any> => {
  var allRules = extendnew({}, baseRules)
  for [ft, patterns] in additionalRules->items()
    const existingFtPatterns = allRules->get(ft, [])

    if (existingFtPatterns->len() > 0)
      allRules[ft] = existingFtPatterns + patterns
    else
      allRules[ft] = patterns
    endif
  endfor

  return allRules
}
