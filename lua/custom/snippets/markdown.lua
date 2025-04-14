-- Markdown snippets for LuaSnip
--
-- USAGE:
--   Type the snippet trigger (e.g., "todo") and press Ctrl-y to expand
--   (using blink.cmp 'default' preset)
--
-- SNIPPETS:
--   todo, check  → - [ ] (unchecked checkbox)
--   done         → - [x] (checked)
--   arrow        → - [>] (forwarded/delegated)
--   tilde        → - [~] (cancelled)
--   li, -        → - (bullet list)
--   ol, 1        → 1. (numbered list)

local ls = require("luasnip")
local s = ls.snippet
local t = ls.text_node
local i = ls.insert_node

return {
  -- Checkbox list items (matching obsidian.nvim states)
  s("todo", { t("- [ ] "), i(1) }),
  s("check", { t("- [ ] "), i(1) }),

  -- Different checkbox states
  s("done", { t("- [x] "), i(1) }),
  s("arrow", { t("- [>] "), i(1) }),
  s("tilde", { t("- [~] "), i(1) }),

  -- Regular list
  s("li", { t("- "), i(1) }),
  s("-", { t("- "), i(1) }),

  -- Numbered list
  s("ol", { t("1. "), i(1) }),
  s("1", { t("1. "), i(1) }),
}
