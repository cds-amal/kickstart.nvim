local ls = require 'luasnip'
local s = ls.snippet
local sn = ls.snippet_node
local i = ls.insert_node
local t = ls.text_node
local f = ls.function_node
local d = ls.dynamic_node

-- Module name node for `mod`: pre-filled with the buffer's file stem, since
-- TLC and SANY refuse a module whose name differs from its file name. It's a
-- dynamicNode (not `i(1, expand(...))`) so the stem is read at expansion time,
-- not when this file is loaded; the name is selected, so just type to replace.
local function module_name()
  return sn(nil, { i(1, vim.fn.expand '%:t:r') })
end

-- The two halves of the header rule, so the closing `=` rule can be sized to
-- match the header exactly (its width moves with the module name).
local rule_left = string.rep('-', 29) .. ' MODULE '
local rule_right = ' ' .. string.rep('-', 29)

return {
  -- `mod` -> module skeleton. Fill the name, then the cursor parks on the
  -- blank line between the header and the closing rule. The closing rule is
  -- regenerated as the name changes (live, via TextChangedI; see init.lua),
  -- so it always spans the same columns as the header.
  s('mod', {
    t(rule_left),
    d(1, module_name, {}),
    t(rule_right),
    t { '', '' },
    i(0),
    t { '', '' },
    f(function(args)
      local name = args[1][1] or ''
      return string.rep('=', #rule_left + #name + #rule_right)
    end, { 1 }),
  }),
}
