local ls = require('luasnip')
local s = ls.snippet
local i = ls.insert_node
local fmt = require('luasnip.extras.fmt').fmt

return {
  -- `merm` -> mermaid code fence
  s(
    'merm',
    fmt(
      [[
        ```mermaid
        {}
        ```
      ]],
      { i(0) }
    )
  ),
}
