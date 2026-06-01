-- lua/plugins/languages/rust-utils.lua
-- Utility functions for Rust buffers (Anchor-flavored).
--
-- The main export is M.toggle_ai: toggle a macro call and its expansion as a
-- mechanical, in-place text transformation:
--
--   ai!(ctx, asset)   <->   ctx.accounts.asset.to_account_info()
--
-- The transformation is derived from the macro's own macro_rules! definition.
-- That definition comes from rust-analyzer (textDocument/definition on the
-- call, then reading the target range) the first time a macro is expanded in
-- a session; until rust-analyzer is attached and ready, a builtin copy of ai!
-- keeps the toggle working. Collapse can never come from the LSP (there is no
-- "un-expand" request), so it always reverse-matches against the parsed rule.

local M = {}

-- ---------------------------------------------------------------------------
-- Lua-pattern helpers
-- ---------------------------------------------------------------------------

local IDENT_CAP = '([%w_]+)'

-- Escape Lua pattern magic characters in a literal string.
local function pat_escape(s)
  return (s:gsub('[%^%$%(%)%%%.%[%]%*%+%-%?]', '%%%0'))
end

-- All matches of `pat` in `line`, as { s, e, caps = {...} } (1-based, incl).
local function find_all(line, pat)
  local out, init = {}, 1
  while true do
    local res = { line:find(pat, init) }
    if not res[1] then
      break
    end
    out[#out + 1] = { s = res[1], e = res[2], caps = { unpack(res, 3) } }
    init = res[2] + 1
  end
  return out
end

-- The match containing 0-based column `col`, or nil.
local function match_at(matches, col)
  for _, m in ipairs(matches) do
    if col + 1 >= m.s and col + 1 <= m.e then
      return m
    end
  end
end

-- ---------------------------------------------------------------------------
-- macro_rules! parsing
-- ---------------------------------------------------------------------------

-- Build matching patterns and renderer data from the parsed parts of a rule.
-- Returns the rule table, or nil and a reason when the shape can't be made
-- exactly reversible.
local function compile_rule(name, params, body)
  local param_pos = {}
  for idx, p in ipairs(params) do
    param_pos[p] = idx
  end

  -- call pattern: name!( a, b )
  local call_pat
  if #params == 0 then
    call_pat = pat_escape(name) .. '!%(%s*%)'
  else
    local arg_caps = {}
    for _ = 1, #params do
      arg_caps[#arg_caps + 1] = IDENT_CAP
    end
    call_pat = pat_escape(name) .. '!%(%s*' .. table.concat(arg_caps, '%s*,%s*') .. '%s*%)'
  end

  -- split the body into literal pieces and metavariables
  local pieces, vars = {}, {}
  local pos = 1
  while true do
    local s, e, var = body:find('%$([%w_]+)', pos)
    if not s then
      pieces[#pieces + 1] = body:sub(pos)
      break
    end
    pieces[#pieces + 1] = body:sub(pos, s - 1)
    vars[#vars + 1] = var
    pos = e + 1
  end

  -- every body metavariable must be a declared parameter, and every parameter
  -- must appear in the body: otherwise collapse can't recover its value
  local used = {}
  for _, v in ipairs(vars) do
    if not param_pos[v] then
      return nil, ('%s!: body uses undeclared metavariable $%s'):format(name, v)
    end
    used[v] = true
  end
  for _, p in ipairs(params) do
    if not used[p] then
      return nil, ('%s!: parameter $%s never appears in the body, so collapse would lose it'):format(name, p)
    end
  end

  -- body pattern: literal pieces escaped; the first occurrence of each
  -- metavariable is a capture, repeats become backreferences so `$x ... $x`
  -- only collapses when both occurrences hold the same identifier
  local cap_of_var, cap_param, parts = {}, {}, {}
  local ncaps = 0
  for idx, piece in ipairs(pieces) do
    parts[#parts + 1] = pat_escape(piece)
    local var = vars[idx]
    if var then
      if cap_of_var[var] then
        parts[#parts + 1] = '%' .. cap_of_var[var]
      else
        ncaps = ncaps + 1
        cap_of_var[var] = ncaps
        cap_param[ncaps] = param_pos[var]
        parts[#parts + 1] = IDENT_CAP
      end
    end
  end

  return {
    name = name,
    params = params,
    body = body,
    param_pos = param_pos,
    call_pat = call_pat,
    body_pat = table.concat(parts),
    cap_param = cap_param,
  }
end

-- Parse the source text of a macro definition into a compiled rule.
-- Surrounding noise (doc comments, `pub(crate) use ...`) is fine; we anchor
-- on `macro_rules!`. Only the simple shape is supported, deliberately: the
-- toggle must be exactly reversible, which is only guaranteed when
--   * there is exactly one rule,
--   * every metavariable is an :ident fragment (no repetitions),
--   * the body is a single-line expression.
-- Anything else returns nil and a human-readable reason.
function M.parse_macro_rules(text)
  local name, block = text:match('macro_rules!%s+([%w_]+)%s*(%b{})')
  if not name then
    return nil, 'no macro_rules! definition found'
  end

  local inner = block:sub(2, -2)
  local _, rule_end, pat, body_block = inner:find('%s*(%b())%s*=>%s*(%b{})')
  if not pat then
    return nil, ('%s!: could not find a `(...) => {...}` rule'):format(name)
  end
  if not inner:sub(rule_end + 1):match('^[%s;]*$') then
    return nil, ('%s!: more than one rule (only single-rule macros are supported)'):format(name)
  end

  -- pattern -> ordered :ident metavariables
  local pat_inner = pat:sub(2, -2)
  if pat_inner:find('%$%(') then
    return nil, ('%s!: repetition in the pattern is not supported'):format(name)
  end
  local params = {}
  local leftover = pat_inner:gsub('%$([%w_]+)%s*:%s*([%w_]+)', function(var, frag)
    params[#params + 1] = { var = var, frag = frag }
    return ''
  end)
  if not leftover:match('^[%s,]*$') then
    return nil, ('%s!: pattern has tokens beyond comma-separated metavariables'):format(name)
  end
  local names = {}
  for _, p in ipairs(params) do
    if p.frag ~= 'ident' then
      return nil, ('%s!: $%s is a :%s fragment (only :ident substitutions are reversible)'):format(name, p.var, p.frag)
    end
    names[#names + 1] = p.var
  end

  -- body -> single-line expression
  local body = vim.trim(body_block:sub(2, -2))
  if body:find('\n') then
    return nil, ('%s!: body spans multiple lines'):format(name)
  end
  if body:find('%$%(') then
    return nil, ('%s!: repetition in the body is not supported'):format(name)
  end

  return compile_rule(name, names, body)
end

-- Render the expansion of `rule` for `args` (list, in call order).
function M.expand_rule(rule, args)
  return (rule.body:gsub('%$([%w_]+)', function(var)
    return args[rule.param_pos[var]]
  end))
end

-- Render the call form of `rule` from a body-pattern match's captures.
function M.collapse_rule(rule, caps)
  local args = {}
  for ci, cap in ipairs(caps) do
    args[rule.cap_param[ci]] = cap
  end
  return rule.name .. '!(' .. table.concat(args, ', ') .. ')'
end

-- ---------------------------------------------------------------------------
-- Known-macro registry
-- ---------------------------------------------------------------------------

-- Rules by macro name. Seeded with a builtin copy of ai! so the toggle works
-- before rust-analyzer has attached (or finished indexing); a builtin entry
-- is replaced by the real, LSP-fetched definition the first time that macro
-- is expanded, so edits to macros.rs win without touching this file.
local registry = {}

local BUILTIN_DEFS = {
  [[
    macro_rules! ai {
        ($ctx:ident, $field:ident) => {
            $ctx.accounts.$field.to_account_info()
        };
    }
  ]],
}

for _, def in ipairs(BUILTIN_DEFS) do
  local rule, err = M.parse_macro_rules(def)
  assert(rule, err)
  rule.source = 'builtin'
  registry[rule.name] = rule
end

-- Exposed for inspection and tests.
M._registry = registry

-- ---------------------------------------------------------------------------
-- LSP definition fetch
-- ---------------------------------------------------------------------------

-- Fetch and parse the macro_rules! definition for the macro whose name starts
-- at 0-based (row, col) in `bufnr`, via textDocument/definition. Synchronous
-- with a short timeout: this runs from an interactive keymap.
--
-- N.B. the position is sent as a byte column; rust-analyzer speaks UTF-16
-- offsets, but macro names are ASCII so the two agree at the positions we
-- send.
local function lsp_fetch_rule(bufnr, row, col)
  if #vim.lsp.get_clients({ bufnr = bufnr }) == 0 then
    return nil, 'no LSP client attached'
  end
  local params = {
    textDocument = { uri = vim.uri_from_bufnr(bufnr) },
    position = { line = row, character = col },
  }
  local resp = vim.lsp.buf_request_sync(bufnr, 'textDocument/definition', params, 2000)
  if not resp then
    return nil, 'definition request timed out'
  end

  -- result may be Location | Location[] | LocationLink[], per client
  local loc
  for _, r in pairs(resp) do
    if r.result then
      loc = r.result.uri and r.result or r.result[1]
      if loc then
        break
      end
    end
  end
  if not loc then
    return nil, 'no definition found'
  end

  local uri = loc.targetUri or loc.uri
  local range = loc.targetRange or loc.range
  local def_buf = vim.uri_to_bufnr(uri)
  local lines
  if vim.api.nvim_buf_is_loaded(def_buf) then
    lines = vim.api.nvim_buf_get_lines(def_buf, range.start.line, range['end'].line + 1, false)
  else
    lines = vim.list_slice(vim.fn.readfile(vim.uri_to_fname(uri)), range.start.line + 1, range['end'].line + 1)
  end
  return M.parse_macro_rules(table.concat(lines, '\n'))
end

-- ---------------------------------------------------------------------------
-- The toggle
-- ---------------------------------------------------------------------------

-- Any `name!(args)` call (paren form; nested parens in args means the args
-- aren't plain identifiers, so such calls are deliberately not matched).
local MACRO_CALL_PAT = '([%w_]+)!%(([^()]*)%)'

-- Pure core, separated for testing: takes the line, the 0-based cursor
-- column, and a resolver(call_start, name) -> rule|nil, reason. Returns
-- new_line, replacement_start (1-based) or nil, reason.
--
-- Priority (cursor first, then line fallback):
--   1. macro call containing the cursor      -> expand
--   2. known expansion containing the cursor -> collapse
--   3. first macro call on the line          -> expand
--   4. first known expansion on the line     -> collapse
function M.toggle_transform(line, col, resolve)
  local calls = find_all(line, MACRO_CALL_PAT)

  local expansions = {}
  for _, rule in pairs(registry) do
    for _, m in ipairs(find_all(line, rule.body_pat)) do
      m.rule = rule
      expansions[#expansions + 1] = m
    end
  end
  table.sort(expansions, function(a, b)
    return a.s < b.s
  end)

  local function expand(call)
    local name, raw_args = call.caps[1], call.caps[2]
    local rule, why = resolve(call.s, name)
    if not rule then
      return nil, ("can't expand %s!: %s"):format(name, why or 'unknown macro')
    end
    local args = {}
    for arg in raw_args:gmatch('[^,]+') do
      arg = vim.trim(arg)
      if not arg:match('^[%w_]+$') then
        return nil, ("can't expand %s!: %q is not a plain identifier"):format(name, arg)
      end
      args[#args + 1] = arg
    end
    if #args ~= #rule.params then
      return nil, ("can't expand %s!: expected %d argument(s), got %d"):format(name, #rule.params, #args)
    end
    return line:sub(1, call.s - 1) .. M.expand_rule(rule, args) .. line:sub(call.e + 1), call.s
  end

  local function collapse(m)
    return line:sub(1, m.s - 1) .. M.collapse_rule(m.rule, m.caps) .. line:sub(m.e + 1), m.s
  end

  -- 1 / 2: cursor priority
  local call_here = match_at(calls, col)
  if call_here then
    return expand(call_here)
  end
  local exp_here = match_at(expansions, col)
  if exp_here then
    return collapse(exp_here)
  end

  -- 3 / 4: line fallback. A failed expand falls through to collapse and is
  -- only reported when nothing else on the line works.
  local expand_err
  if calls[1] then
    local new, pos_or_err = expand(calls[1])
    if new then
      return new, pos_or_err
    end
    expand_err = pos_or_err
  end
  if expansions[1] then
    return collapse(expansions[1])
  end
  if expand_err then
    return nil, expand_err
  end

  if line:find('%.to_account_info%(%)') then
    return nil, 'to_account_info() receiver does not match any known macro expansion'
  end
  return nil, 'no macro call or known macro expansion on this line'
end

-- Buffer-facing entry point, bound to ,tai in ftplugin/rust.lua. Keeps the
-- cursor at the start of the rewritten expression.
function M.toggle_ai()
  local bufnr = vim.api.nvim_get_current_buf()
  local row, col = unpack(vim.api.nvim_win_get_cursor(0))
  local line = vim.api.nvim_get_current_line()

  local new_line, start_or_reason = M.toggle_transform(line, col, function(call_start, name)
    -- Builtin entries are refreshed via LSP so the toggle tracks the real
    -- definition; LSP-confirmed entries are reused for the session.
    local rule = registry[name]
    if rule and rule.source == 'lsp' then
      return rule
    end
    local fetched, why = lsp_fetch_rule(bufnr, row - 1, call_start - 1)
    if fetched then
      fetched.source = 'lsp'
      registry[fetched.name] = fetched
      return fetched
    end
    if rule then
      return rule -- builtin fallback: rust-analyzer not attached or not ready
    end
    return nil, why
  end)

  if not new_line then
    vim.notify(start_or_reason, vim.log.levels.WARN)
    return
  end
  vim.api.nvim_set_current_line(new_line)
  vim.api.nvim_win_set_cursor(0, { row, start_or_reason - 1 })
end

return M
