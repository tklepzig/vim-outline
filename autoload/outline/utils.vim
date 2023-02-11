vim9script

export const GetIndent = (line): number => 
  match(line[stridx(trim(line), " ") :], "[^ ]")

export const GetType = (line: string): string => {
  if line =~ "describe"
    return "describe"
  elseif line =~ "context"
    return "context"
  elseif line =~ "it"
    return "it"
  endif
  return "unknown"
}  

export const CollectBlocks = (keyword: string): string => {
  try
    return execute('g/\v^\s*' .. keyword)
  catch
    return ""
  endtry
}

