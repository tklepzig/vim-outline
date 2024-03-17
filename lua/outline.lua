local bufferName = "outline"

local function find_matches(pattern)
  local status, result = pcall(vim.api.nvim_exec2, 'g/\\v^\\s*' .. pattern .. '.*$', { output = true })
  if status then
    return result.output
  else
    return ""
  end
end

local function text_from_result(line)
  local spaceidx = assert(string.find(vim.trim(line), " "))
  return string.sub(line, spaceidx + 1)
end

local function indent_from_result(line)
  local first_non_space_index = assert(string.find(text_from_result(line), "[^ ]"))
  -- subtract 1 because lua is 1-based
  return first_non_space_index - 1
end

local function line_nr_from_result(line)
  return tonumber(string.match(line, "^%d+"))
end

local function replace_with_first_group(text, pattern)
  return string.gsub(text, "^%s*" .. pattern .. ".*$", "%1")
end

local function merge_rules(base_rules, additional_rules)
  local all_rules = vim.tbl_deep_extend("force", {}, base_rules)
  for ft, patterns in pairs(additional_rules) do
    local existing_ft_patterns = all_rules[ft] or {}

    if #existing_ft_patterns > 0 then
      all_rules[ft] = vim.list_extend(existing_ft_patterns, patterns)
    else
      all_rules[ft] = patterns
    end
  end

  return all_rules
end

local builtin_rules = {
  ruby = {
    { "describe '(.*)'" },
    { "context '(.*)'", "OutlineHighlight2" },
    { "it '(.*)'",      "OutlineHighlight1" },
    { 'def ([^\\(]*)',  "OutlineHighlight1" },
    { 'class (.*)',     "OutlineHighlight2" },
    { 'module123 (.*)', "OutlineHighlight2" },
  },
  typescript_tsx = {
    { '.*const ([^=]*) \\= \\(.*\\) \\=\\>' },
    { '.*interface (.*)\\s*\\{',            "OutlineHighlight2" },
    { '.*type (.*)\\s*\\=',                 "OutlineHighlight2" },
    { "describe\\([\"'](.*)[\"']," },
    { "it\\([\"'](.*)[\"'],",               "OutlineHighlight1" },
  },
  typescript = {
    { '.*const ([^=]*) \\= \\(.*\\) \\=\\>' },
    { '.*interface (.*)\\s*\\{',            "OutlineHighlight2" },
    { '.*type (.*)\\s*\\=',                 "OutlineHighlight2" },
    { "describe\\([\"'](.*)[\"']," },
    { "it\\([\"'](.*)[\"'],",               "OutlineHighlight1" },
  },
  markdown = {
    { '(# .*)' },
    { '(## .*)' },
    { '(### .*)' },
    { '(#### .*)' },
    { '(##### .*)' },
    { '(###### .*)' },
  },
}

local function build()
  local rules = merge_rules(builtin_rules, {})
  local items = rules[vim.bo.filetype] or {}
  local view = vim.fn.winsaveview()
  local result = {}

  for _, item in ipairs(items) do
    local pattern, highlight = unpack(item)
    highlight = highlight or "no-highlight"
    local matches = find_matches(pattern)
    local lines = vim.split(assert(matches), "\n")

    for _, line in ipairs(lines) do
      line = vim.trim(line)

      local lineNr = line_nr_from_result(line)
      if lineNr ~= nil then
        table.insert(result, {
          lineNr = lineNr,
          highlight = highlight,
          text = replace_with_first_group(text_from_result(line), pattern),
          indent = indent_from_result(line)
        })
      end
    end
  end

  vim.fn.winrestview(assert(view))

  local function compare(a, b)
    return a.lineNr < b.lineNr
  end

  table.sort(result, compare)

  for _, v in ipairs(result) do
    print(v.text, v.indent, v.lineNr, v.highlight)
  end

  return result
end

local function open()
  local outlineBuffer = vim.api.nvim_call_function('bufnr', { bufferName })
  if outlineBuffer > 0 and vim.fn.bufexists(outlineBuffer) then
    return
  end

  vim.cmd("aboveleft vsplit")
  local buf = vim.api.nvim_create_buf(false, false)
  vim.api.nvim_win_set_buf(0, buf)
  vim.api.nvim_win_set_width(0, 40)
  -- Use manual cmd including silent instead of nvim_buf_set_name to avoid printing "--No lines in buffer--"
  vim.cmd("silent file " .. bufferName)

  vim.cmd("setlocal filetype=outline")
  vim.cmd("setlocal readonly nomodifiable")
end

local function test()
  build()
end

return {
  open = open,
  test = test
}
