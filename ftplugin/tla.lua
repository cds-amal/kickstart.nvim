-- ftplugin/tla.lua
-- TLA+ buffer settings and keymaps.

-- Neovim ships no syntax/tla.vim, so treesitter is the only highlighter.
vim.treesitter.start()

vim.opt_local.commentstring = [[\* %s]]

local map = function(lhs, rhs, desc)
  vim.keymap.set('n', lhs, rhs, { buffer = true, desc = desc })
end

map('<localleader>c', '<Cmd>TlaCheck<CR>', 'TLA+: model check with TLC')
map('<localleader>t', '<Cmd>TlaTranslate<CR>', 'TLA+: translate PlusCal')

-- Every Unicode keymap starts with a backslash, so after `\` Neovim waits
-- 'timeoutlen' (300ms here) for the rest; type `\E` any slower and the
-- backslash lands literally. The same goes for `=`: `==`, `=>` and `=|` all
-- start with it. Abbreviations expand on the character typed after the word
-- instead of on a timer, so they back up the keymaps for the `\word`
-- operators and for `==`: fast typing hits the keymap, slow typing the
-- abbreviation. An abbreviation ending in a non-keyword character (a
-- "non-id" one, which `==` is unless `=` is in 'iskeyword') expands only on
-- <Esc>, <CR> and <C-]>, whatever :help abbreviations says about space; one
-- made entirely of keyword characters expands on the space too. So `\` and
-- `=` join 'iskeyword', which also makes `w` and `*` treat `\in` and `x=1`
-- as one word, a fair reading of TLA+. The remaining symbolic operators
-- (`/\`, `\/`, `<<`) stay keymap-only rather than pull `/` and `<` into
-- 'iskeyword' too.
vim.opt_local.iskeyword:append { [[\]], '=' }

local function unicode_csv()
  local plugin = require('lazy.core.config').plugins['tlaplus-nvim-plugin']
  return vim.fn.readfile(plugin.dir .. '/plugin/tla-unicode.csv')
end

local function abbreviated_words()
  local words, seen = {}, {}
  for _, line in ipairs(unicode_csv()) do
    local _, ascii, unicode = unpack(vim.split(line, ','))
    for _, variant in ipairs(vim.split(ascii or '', ';')) do
      if (variant:match '^\\%a+$' or variant == '==') and not seen[variant] then
        seen[variant] = true
        table.insert(words, { variant, unicode })
      end
    end
  end
  return words
end

-- Keymaps and abbreviations only see typed insert-mode input; `:s`, paste
-- and external pipes write straight into the buffer, so their ASCII stays
-- ASCII. The converter below sweeps that up after the fact. It scans each
-- line like a tokenizer (at every position the longest matching operator
-- wins) instead of running one global substitute per operator, because
-- sequential substitutes misfire on overlaps: `<-` inside `<<-3, 2>>`
-- must lose to `<<`, and the `====` module footer must not read as `==`.

local escape_pattern = function(s)
  return (s:gsub('[%^%$%(%)%%%.%[%]%*%+%-%?]', '%%%0'))
end

local rule_buckets

-- Builds the operator table from the plugin's CSV, one rule per ASCII
-- variant, bucketed by first byte so the scanner only tries rules that
-- can possibly match at the current position.
local function conversion_rules()
  if rule_buckets then return rule_buckets end
  local all, seen = {}, {}
  local csv = unicode_csv()
  for i = 2, #csv do -- row 1 is the header
    local _, ascii, unicode = unpack(vim.split(csv[i], ','))
    for _, variant in ipairs(vim.split(ascii or '', ';')) do
      if variant ~= '' and not seen[variant] then
        seen[variant] = true
        local rule = { len = #variant, order = #all, replacement = unicode, first = variant:sub(1, 1) }
        if variant:match [[^\%a+$]] then
          -- a following letter means a longer operator is underway
          -- (\in vs \intersect), so require a non-letter after
          rule.pattern = '^' .. escape_pattern(variant) .. '%f[%A]'
        elseif variant:match '^%a+$' then
          -- Nat, Int, Real: whole identifiers only (Interval keeps its Int)
          rule.pattern = '^' .. variant .. '%f[%W]'
          rule.needs_word_start = true
        elseif variant == '==' then
          -- exactly two: the ==== module footer is not a definition
          rule.pattern = '^==%f[^=]'
          rule.not_after = '='
        else
          rule.pattern = '^' .. escape_pattern(variant)
        end
        table.insert(all, rule)
      end
    end
  end
  table.sort(all, function(a, b)
    if a.len ~= b.len then return a.len > b.len end
    return a.order < b.order
  end)
  rule_buckets = {}
  for _, rule in ipairs(all) do
    rule_buckets[rule.first] = rule_buckets[rule.first] or {}
    table.insert(rule_buckets[rule.first], rule)
  end
  return rule_buckets
end

local function convert_chunk(s, buckets)
  local out, i, n = {}, 1, #s
  while i <= n do
    local replaced = false
    local bucket = buckets[s:sub(i, i)]
    if bucket then
      local prev = i > 1 and s:sub(i - 1, i - 1) or ''
      for _, rule in ipairs(bucket) do
        if not (rule.needs_word_start and prev:match '[%w_]') and not (rule.not_after == prev) then
          local _, last = s:find(rule.pattern, i)
          if last then
            table.insert(out, rule.replacement)
            i = last + 1
            replaced = true
            break
          end
        end
      end
    end
    if not replaced then
      table.insert(out, s:sub(i, i))
      i = i + 1
    end
  end
  return table.concat(out)
end

-- String literals and `\*` line comments keep their ASCII: a "->" inside a
-- string is data, and prose like ~10ms would otherwise grow a ¬. Block
-- comment bodies do get converted; treating (* *) as opaque needs
-- multi-line state this line-by-line pass does not track.
local function convert_line(line, buckets)
  local out, i = {}, 1
  while true do
    local quote = line:find('"', i, true)
    local comment = line:find([[\*]], i, true)
    if comment and (not quote or comment < quote) then
      table.insert(out, convert_chunk(line:sub(i, comment - 1), buckets))
      table.insert(out, line:sub(comment))
      return table.concat(out)
    elseif quote then
      table.insert(out, convert_chunk(line:sub(i, quote - 1), buckets))
      -- find the closing quote, stepping over \" escapes
      local j = quote + 1
      while true do
        local k = line:find('"', j, true)
        if not k then
          j = #line + 1
          break
        end
        j = k + 1
        local backslashes, p = 0, k - 1
        while p >= 1 and line:sub(p, p) == '\\' do
          backslashes, p = backslashes + 1, p - 1
        end
        if backslashes % 2 == 0 then break end
      end
      table.insert(out, line:sub(quote, j - 1))
      i = j
      if i > #line then return table.concat(out) end
    else
      table.insert(out, convert_chunk(line:sub(i), buckets))
      return table.concat(out)
    end
  end
end

local function convert_range(line1, line2)
  local buckets = conversion_rules()
  local view = vim.fn.winsaveview()
  local changed = 0
  for lnum = line1, line2 do
    local line = vim.fn.getline(lnum)
    local new = convert_line(line, buckets)
    if new ~= line then
      vim.fn.setline(lnum, new)
      changed = changed + 1
    end
  end
  vim.fn.winrestview(view)
  return changed
end

vim.api.nvim_buf_create_user_command(0, 'TlaUnicode', function(opts)
  local n = convert_range(opts.line1, opts.line2)
  vim.notify(('TLA+ Unicode: converted %d line%s'):format(n, n == 1 and '' or 's'))
end, { range = '%', desc = 'TLA+: convert ASCII operators to Unicode' })

-- While the Unicode mappings are on, saving sweeps up any ASCII that got
-- past them, so the <leader>tm toggle governs the whole buffer, however the
-- text arrived.
vim.api.nvim_create_autocmd('BufWritePre', {
  group = vim.api.nvim_create_augroup('tla-unicode-' .. vim.api.nvim_get_current_buf(), { clear = true }),
  buffer = 0,
  callback = function()
    if vim.b.tlaplus_mappings_defined then
      convert_range(1, vim.fn.line '$')
    end
  end,
  desc = 'TLA+: ASCII to Unicode on save while mappings are on',
})

-- tlaplus-nvim-plugin tracks its state in b:tlaplus_mappings_defined.
map('<leader>tm', function()
  if vim.b.tlaplus_mappings_defined then
    vim.cmd 'TlaMappingsRemove'
    for _, word in ipairs(abbreviated_words()) do
      vim.keymap.del('ia', word[1], { buffer = true })
    end
    vim.notify 'TLA+ Unicode mappings off'
  else
    vim.cmd 'TlaMappingsAdd'
    for _, word in ipairs(abbreviated_words()) do
      vim.keymap.set('ia', word[1], word[2], { buffer = true, desc = 'TLA+ ' .. word[2] })
    end
    vim.notify 'TLA+ Unicode mappings on'
  end
end, 'TLA+: toggle Unicode input mappings')
