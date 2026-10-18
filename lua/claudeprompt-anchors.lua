-- Pure helpers behind the `code_anchors` slot of lua/snippets/claudeprompt.lua:
-- turn the clipboard block copy-with-context (<leader>cy) writes into the
-- anchor lines the prompt carries. No vim.* here, so
-- tests/claudeprompt-anchors-test.lua runs under plain Lua 5.1.

local M = {}

-- copy-with-context writes `<code>\n# {filepath}:{line}`, line being `12`
-- or `12-20`. The header is the LAST matching line: a `#` comment inside the
-- copied code that happens to look like a header only wins when no real
-- header follows it. The greedy `.+` keeps a colon inside the path and takes
-- the final `:digits` as the range.
local HEADER = '^# (.+):(%d+%-?%d*)$'

local function split_lines(text)
  local lines = {}
  for line in (text .. '\n'):gmatch '(.-)\n' do
    -- A CRLF clipboard (a copy from a Windows-origin file) would otherwise
    -- carry \r into the fence and stop the header from matching.
    lines[#lines + 1] = (line:gsub('\r$', ''))
  end
  return lines
end

local function trim_blank(lines)
  local first, last = 1, #lines
  while first <= last and lines[first]:match '^%s*$' do
    first = first + 1
  end
  while last >= first and lines[last]:match '^%s*$' do
    last = last - 1
  end
  local out = {}
  for i = first, last do
    out[#out + 1] = lines[i]
  end
  return out
end

--- Parse a copy-with-context clipboard block.
--- @param text string|nil register contents
--- @return { path: string, range: string, code: string[] }|nil
function M.parse(text)
  if type(text) ~= 'string' then
    return nil
  end
  local lines = split_lines(text)
  local header_at
  for i = #lines, 1, -1 do
    if lines[i]:match(HEADER) then
      header_at = i
      break
    end
  end
  if not header_at then
    return nil
  end
  local path, range = lines[header_at]:match(HEADER)
  local code = {}
  for i, line in ipairs(lines) do
    if i ~= header_at then
      code[#code + 1] = line
    end
  end
  return { path = path, range = range, code = trim_blank(code) }
end

--- Render a parsed block as unindented anchor lines: `path:range`, then the
--- code in a fence. The fence is there because the prompt body is read as
--- markdown, and a fence keeps leading whitespace and `<` from being misread.
--- @param anchor { path: string, range: string, code: string[] }
--- @param lang string|nil fence language; nil renders a bare fence
--- @return string[]
function M.render(anchor, lang)
  local out = { anchor.path .. ':' .. anchor.range }
  if #anchor.code == 0 then
    return out
  end
  -- Code copied from a markdown file can hold its own ``` line, which would
  -- close the anchor's fence early; CommonMark closes a fence only with a run
  -- at least as long as the opener, so use one longer than any run inside.
  local longest = 2
  for _, line in ipairs(anchor.code) do
    for run in line:gmatch '`+' do
      longest = math.max(longest, #run)
    end
  end
  local fence = string.rep('`', longest + 1)
  out[#out + 1] = fence .. (lang or '')
  for _, line in ipairs(anchor.code) do
    out[#out + 1] = line
  end
  out[#out + 1] = fence
  return out
end

return M
