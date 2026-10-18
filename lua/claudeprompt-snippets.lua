-- The snippets for Claude Code's C-x C-e editor buffer (filetype
-- markdown.claudeprompt, set in lua/filetypes.lua): `prompt` is the whole
-- XML skeleton, `anchor` adds one more code anchor from the clipboard.
-- lua/snippets/claudeprompt.lua hands M.snippets to LuaSnip's loader; the
-- module exists so the one effect, reading the clipboard, is a field a test
-- can replace instead of swapping Neovim's clipboard provider.
local ls = require 'luasnip'
local s = ls.snippet
local sn = ls.snippet_node
local i = ls.insert_node
local d = ls.dynamic_node
local fmt = require('luasnip.extras.fmt').fmt
local anchors = require 'claudeprompt-anchors'

local M = {}

local ANCHOR_HINT = 'real file:line for the files that matter, plus a pattern to copy'

-- Read at expansion time, so a stale clipboard pastes stale code: it lands
-- at the cursor, where it is seen before the prompt is sent.
function M.read_clipboard()
  return vim.fn.getreg '+'
end

-- One value, so render's optional second argument is exactly the language.
local function lang_of(path)
  local ft = vim.filetype.match { filename = path }
  return ft
end

-- The clipboard as copy-with-context (<leader>cy) left it, rendered as an
-- anchor block, or the hint when it holds anything else.
local function anchor_lines()
  local parsed = anchors.parse(M.read_clipboard())
  if not parsed then
    return { ANCHOR_HINT }
  end
  return anchors.render(parsed, lang_of(parsed.path))
end

-- An editable, Tab-reachable slot holding the anchor block. `indent` is
-- prefixed to every line after the first: LuaSnip indents continuation lines
-- by the whitespace before the trigger, which is the body indent when
-- `anchor` is typed inside a section, but column 0 for `prompt`, whose
-- code_anchors body sits two spaces in.
local function anchor_node(jump_index, indent)
  return d(jump_index, function()
    local lines = anchor_lines()
    for n = 2, #lines do
      lines[n] = indent .. lines[n]
    end
    return sn(nil, { i(1, lines) })
  end, {})
end

M.snippets = {
  s(
    'prompt',
    fmt(
      [[
        <prompt>
        <role>You are a careful engineer working in this repo. One rule: verify, don't guess. Read the code before claiming what it does; run the check before claiming it passes.</role>
        <mission>{}</mission>
        <scope>
          <in>{}</in>
          <out>{}</out>
        </scope>
        <context>
          {}
        </context>
        <code_anchors>
          {}
        </code_anchors>
        <success_criteria>
          {}
        </success_criteria>
        <verification>{}</verification>
        </prompt>
      ]],
      {
        i(1, 'one sentence, one outcome'),
        i(2, 'what to touch'),
        i(3, 'what to leave alone'),
        i(4, "decisions already made, so they don't get reopened"),
        anchor_node(5, '  '),
        i(6, "how you'll know it worked, in checks you can run"),
        -- The exit node carries hint text too (verified: ExitNode accepts
        -- static text), so the last Tab lands on the command, the section
        -- history shows is skipped most.
        i(0, 'the exact command to run'),
      }
    )
  ),

  s('anchor', { anchor_node(1, '') }),
}

return M
