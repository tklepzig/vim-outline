local bufferName = "outline"

local function findMatches(pattern)
  local status, result = pcall(vim.api.nvim_exec2, 'g/\\v^\\s*' .. pattern .. '.*$', { output = true })
  if status then
    return result.output
  else
    return ""
  end
end

local function TextFromResult(line)
  local spaceidx = assert(string.find(vim.trim(line), " "))
  return string.sub(line, spaceidx + 1)
end

function IndentFromResult(line)
  local firstNonSpaceIndex = assert(string.find(TextFromResult(line), "[^ ]"))
  -- subtract 1 because lua is 1-based
  return firstNonSpaceIndex - 1
end

local function LineNrFromResult(line)
  return tonumber(string.match(line, "^%d+"))
end

local function ReplaceWithFirstGroup(text, pattern)
  return string.gsub(text, "^%s*" .. pattern .. ".*$", "%1")
end

local function MergeRules(baseRules, additionalRules)
  local allRules = vim.tbl_deep_extend("force", {}, baseRules)
  for ft, patterns in pairs(additionalRules) do
    local existingFtPatterns = allRules[ft] or {}

    if #existingFtPatterns > 0 then
      allRules[ft] = vim.list_extend(existingFtPatterns, patterns)
    else
      allRules[ft] = patterns
    end
  end

  return allRules
end

local g_rules = {
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

function Build()
  local rules = MergeRules(g_rules, {})
  local items = rules[vim.bo.filetype] or {}
  local view = vim.fn.winsaveview()
  local result = {}

  for _, item in ipairs(items) do
    local pattern, highlight = unpack(item)
    highlight = highlight or "no-highlight"
    local matches = findMatches(pattern)
    local lines = vim.split(assert(matches), "\n")

    for _, line in ipairs(lines) do
      line = vim.trim(line)

      local lineNr = LineNrFromResult(line)
      if lineNr ~= nil then
        table.insert(result, {
          lineNr = lineNr,
          highlight = highlight,
          text = ReplaceWithFirstGroup(TextFromResult(line), pattern),
          indent = IndentFromResult(line)
        })
      end
    end
  end

  vim.fn.winrestview(assert(view))

  local function compare(a, b)
    return a.lineNr < b.lineNr
  end

  table.sort(result, compare)

  for k, v in ipairs(result) do
    print(v.text, v.indent, v.lineNr, v.highlight)
  end

  return result
end

local function open()
  vim.cmd("aboveleft vsplit")
  local buf = vim.api.nvim_create_buf(false, false)

  vim.api.nvim_buf_set_option(buf, "filetype", "outline")
  vim.api.nvim_buf_set_option(buf, "readonly", true)
  vim.api.nvim_buf_set_option(buf, "modifiable", false)
  vim.api.nvim_buf_set_option(buf, "buftype", "nofile")
  vim.api.nvim_buf_set_option(buf, "bufhidden", "wipe")
  vim.api.nvim_buf_set_option(buf, "swapfile", false)

  vim.api.nvim_win_set_option(0, "wrap", false)
  vim.api.nvim_win_set_option(0, "number", false)
  vim.api.nvim_win_set_option(0, "relativenumber", false)
  vim.api.nvim_win_set_option(0, "foldenable", false)
  vim.api.nvim_win_set_width(0, 40)

  vim.api.nvim_win_set_buf(0, buf)
  -- Use manual cmd including silent instead of nvim_buf_set_name to avoid printing "--No lines in buffer--"
  vim.cmd("silent file " .. bufferName)
end

local function test()
  Build()
end

return {
  open = open,
  test = test
}
