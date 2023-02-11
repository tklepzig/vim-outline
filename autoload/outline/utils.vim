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

