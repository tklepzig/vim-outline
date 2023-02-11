vim9script

export const GetIndent = (line): number => 
  match(line[stridx(trim(line), " ") :], "[^ ]")

export const FindMatches = (pattern: string): string => {
  try
    return execute('g/\v^\s*' .. pattern)
  catch
    return ""
  endtry
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
