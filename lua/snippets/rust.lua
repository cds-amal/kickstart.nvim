local ls = require('luasnip')
local s = ls.snippet
local sn = ls.snippet_node
local i = ls.insert_node
local t = ls.text_node
local f = ls.function_node
local c = ls.choice_node
local d = ls.dynamic_node
local fmt = require('luasnip.extras.fmt').fmt
local fmta = require('luasnip.extras.fmt').fmta
local rep = require('luasnip.extras').rep
-- Key node reference, for mirroring a node from a different scope (e.g. a node
-- nested inside a choiceNode); plain rep(<index>) is scope-local and can't see
-- across that boundary.
local k = require('luasnip.nodes.key_indexer').new_key

-- Recursive tail for the `errc` enum: a choiceNode whose default is empty
-- (so <Esc><Esc> finishes the snippet) and whose second choice is another
-- variant/msg pair followed by *another* copy of this same tail. Cycle to the
-- second choice with <C-f> to grow the enum one pair at a time. The sn(...)
-- must NOT be the first choice; LuaSnip renders all choices eagerly and a
-- leading self-reference would recurse forever.
local err_pair
err_pair = function()
  return sn(nil, {
    c(1, {
      t(''),
      sn(nil, {
        -- variant is i(1) so Tab reaches it before the msg at i(2),
        -- matching the NAME -> variant -> msg jump order of the parent.
        t({ '', '    #[msg("' }),
        i(2),
        t('")]'),
        t({ '', '    ' }),
        i(1),
        t(','),
        d(3, err_pair, {}),
      }),
    }),
  })
end

-- Optional `#[account(...)]` line shared by the field snippets below. Returns
-- a choiceNode at jump index `idx` whose choices are ordered so `default`
-- comes first (and is therefore what you land on). The two attribute choices
-- carry their own trailing newline so the field's `pub ...` line follows; the
-- 'none' choice is empty, leaving an attr-less field on a single line. Cycle
-- between them with <C-f>/<C-b>.
local function attr_choice(idx, default)
  local build = {
    mut = function() return sn(nil, { t({ '#[account(mut)]', '' }) }) end,
    custom = function() return sn(nil, { t('#[account('), i(1, 'mut'), t({ ')]', '' }) }) end,
    none = function() return t('') end,
  }
  local order = {
    mut = { 'mut', 'custom', 'none' },
    custom = { 'custom', 'mut', 'none' },
    none = { 'none', 'mut', 'custom' },
  }
  local choices = {}
  for _, kind in ipairs(order[default]) do
    choices[#choices + 1] = build[kind]()
  end
  return c(idx, choices)
end

-- Field type choice for the PDA snippet: the same mut/seeds/bump constraint
-- block can sit on an Account, an UncheckedAccount (signer-only PDAs, like an
-- `update_authority`), or an InterfaceAccount. Returns a choiceNode at jump
-- index `idx`; cycle with <C-f>.
local function acct_type(idx)
  return c(idx, {
    sn(nil, { t("Account<'info, "), i(1, 'Type'), t('>') }),
    t("UncheckedAccount<'info>"),
    sn(nil, { t("InterfaceAccount<'info, "), i(1, 'Type'), t('>') }),
  })
end

-- Scan the current buffer for `#[derive(... Accounts ...)]` structs and return
-- their names in source order. Attribute lines (e.g. #[instruction(...)]) may
-- sit between the derive and the `pub struct`, so we stay "armed" across them
-- and only disarm on a non-attribute, non-struct line.
local function accounts_structs()
  local names = {}
  local armed = false
  for _, line in ipairs(vim.api.nvim_buf_get_lines(0, 0, -1, false)) do
    if line:match('#%[%s*derive%b()') and line:match('Accounts') then
      armed = true
    elseif armed then
      local name = line:match('pub%s+struct%s+([%w_]+)')
      if name then
        names[#names + 1] = name
        armed = false
      elseif line:match('%S') and not line:match('^%s*#') then
        armed = false
      end
    end
  end
  return names
end

-- dynamicNode body for `hand`: offer the buffer's Accounts structs as choices
-- for the Context<...> type, with a free-text node last (and as the sole option
-- when the buffer has none, e.g. the handler lives in its own file). Generated
-- once at expansion, so write the struct before firing `hand`.
local function ctx_node()
  local choices = {}
  for _, name in ipairs(accounts_structs()) do
    choices[#choices + 1] = t(name)
  end
  choices[#choices + 1] = sn(nil, { i(1, 'Accounts') })
  return sn(nil, { c(1, choices) })
end

return {
  -- `tfn` -> bare #[test] fn
  s(
    'tfn',
    fmt(
      [[
        #[test]
        fn {}() {{
            {}
        }}
      ]],
      { i(1, 'it_works'), i(0) }
    )
  ),

  -- `tfnr` -> #[test] fn returning Result<(), E> (for `?`-using tests)
  s(
    'tfnr',
    fmt(
      [[
        #[test]
        fn {}() -> Result<(), {}> {{
            {}
            Ok(())
        }}
      ]],
      { i(1, 'it_works'), i(2, 'Box<dyn std::error::Error>'), i(0) }
    )
  ),

  -- `tfna` -> async test (tokio)
  s(
    'tfna',
    fmt(
      [[
        #[tokio::test]
        async fn {}() {{
            {}
        }}
      ]],
      { i(1, 'it_works'), i(0) }
    )
  ),

  -- `tmod` -> standard test module skeleton
  s(
    'tmod',
    fmta(
      [[
        #[cfg(test)]
        mod tests {
            use super::*;

            #[test]
            fn <>() {
                <>
            }
        }
      ]],
      { i(1, 'it_works'), i(0) }
    )
  ),

  -- `tcase` -> assert_eq! with labelled actual/expected
  s(
    'tcase',
    fmt(
      [[
        #[test]
        fn {}() {{
            let actual = {};
            let expected = {};
            assert_eq!(actual, expected);
        }}
      ]],
      { i(1, 'name'), i(2, 'todo!()'), i(3, 'todo!()') }
    )
  ),

  -- `tpanic` -> #[should_panic] test
  s(
    'tpanic',
    fmta(
      [[
        #[test]
        #[should_panic(expected = "<>")]
        fn <>() {
            <>
        }
      ]],
      { i(1, 'message'), i(2, 'it_panics'), i(0) }
    )
  ),

  -- `ptmod` -> empty proptest! { ... } wrapper (use `ptfn` inside)
  s(
    'ptmod',
    fmt(
      [[
        proptest! {{
            {}
        }}
      ]],
      { i(0) }
    )
  ),

  -- `ptfn` -> single proptest test (use inside an existing proptest! block)
  s(
    'ptfn',
    fmt(
      [[
        #[test]
        fn {}({} in {}) {{
            {}
        }}
      ]],
      { i(1, 'prop_name'), i(2, 'x'), i(3, 'any::<u32>()'), i(0) }
    )
  ),

  -- `peq` -> prop_assert_eq! with actual / expected
  s(
    'peq',
    fmt('prop_assert_eq!({}, {});', { i(1, 'actual'), i(2, 'expected') })
  ),

  -- `passert` -> prop_assert!(cond)
  s(
    'passert',
    fmt('prop_assert!({});', { i(1, 'cond') })
  ),

  -- `passume` -> prop_assume!(cond) to skip cases
  s(
    'passume',
    fmt('prop_assume!({});', { i(1, 'cond') })
  ),

  -- =============================================================
  -- Anchor / Solana
  -- =============================================================

  -- `errc` -> #[error_code] enum. Fill the name, then jump NAME -> variant
  -- -> msg through the first pair. The trailing choiceNode starts empty, so
  -- <Esc><Esc> finishes here; press <C-f> to add another variant/msg pair
  -- (repeatable). See `err_pair` above for why the tail is shaped this way.
  s(
    'errc',
    fmta(
      [[
        #[error_code]
        pub enum <> {
            #[msg("<>")]
            <>,<>
        }
      ]],
      { i(1, 'ErrorCode'), i(3), i(2), d(4, err_pair, {}) }
    )
  ),

  -- `instr` -> #[derive(Accounts)] struct skeleton. Fill the name, then the
  -- cursor parks inside the braces so you can fire the field triggers below
  -- (acc, sgn, uacc, pda, initacc, prog, sys) one after another, top to
  -- bottom. Stop by just not typing another trigger.
  s(
    'instr',
    fmt(
      [[
        #[derive(Accounts)]
        pub struct {}<'info> {{
            {}
        }}
      ]],
      { i(1, 'Name'), i(0) }
    )
  ),

  -- `acc` -> Account<'info, T> field. You land on the attr line first
  -- (#[account(mut)] by default); <C-f> cycles mut -> custom -> none, then Tab
  -- to the field name and its type.
  s('acc', {
    attr_choice(1, 'mut'),
    t('pub '),
    i(2, 'name'),
    t(": Account<'info, "),
    i(3, 'Type'),
    t('>,'),
  }),

  -- `sgn` -> Signer<'info> field. Signers are usually mut, so the attr line
  -- defaults to #[account(mut)]; <C-f> to change or drop it.
  s('sgn', {
    attr_choice(1, 'mut'),
    t('pub '),
    i(2, 'name'),
    t(": Signer<'info>,"),
  }),

  -- `uacc` -> UncheckedAccount<'info> with the mandatory /// CHECK doc. The
  -- attr defaults to custom (#[account(...)]) since these usually carry an
  -- `address =` or seeds constraint; <C-f> to switch to mut or drop it.
  s('uacc', {
    t('/// CHECK: '),
    i(1, 'why this is safe'),
    t({ '', '' }),
    attr_choice(2, 'custom'),
    t('pub '),
    i(3, 'name'),
    t(": UncheckedAccount<'info>,"),
  }),

  -- `pda` -> mutable PDA (seeds + bump). The field type is a choice: Account,
  -- UncheckedAccount, or InterfaceAccount; <C-f> on the type to switch.
  s(
    'pda',
    fmta(
      [[
        #[account(
            mut,
            seeds = [<>],
            bump,
        )]
        pub <>: <>,
      ]],
      { i(1, 'SEED'), i(2, 'name'), acct_type(3) }
    )
  ),

  -- `initacc` -> init account (payer/space/seeds/bump). The Type is typed once
  -- (i2, in the field type) and mirrored into the space expression via rep(2).
  -- The space line is a choice: <C-f> toggles between the discriminator-length
  -- form and the literal `8 +` form.
  s('initacc', {
    t({ '#[account(', '    init,', '    payer = ' }),
    i(1, 'payer'),
    t({ ',', '    space = ' }),
    c(2, {
      sn(nil, { rep(k('ty')), t('::DISCRIMINATOR.len() + '), rep(k('ty')), t('::INIT_SPACE') }),
      sn(nil, { t('8 + '), rep(k('ty')), t('::INIT_SPACE') }),
    }),
    t({ ',', '    seeds = [' }),
    i(3, 'SEED'),
    t({ '],', '    bump,', ')]', 'pub ' }),
    i(4, 'name'),
    t(": Account<'info, "),
    i(5, 'Type', { key = 'ty' }),
    t('>,'),
  }),

  -- `imint` -> init a token mint via the token interface
  -- (mint::decimals / mint::authority + InterfaceAccount<'info, Mint>). Built
  -- from text nodes rather than fmta because the literal `<'info, Mint>` would
  -- collide with fmta's `<>` placeholder syntax.
  s('imint', {
    t({ '#[account(', '    init,', '    payer = ' }),
    i(1, 'admin'),
    t({ ',', '    mint::decimals = ' }),
    i(2, '6'),
    t({ ',', '    mint::authority = ' }),
    i(3, 'config'),
    t({ ',', '    seeds = [' }),
    i(4, 'SEED'),
    t({ '],', '    bump,', ')]', 'pub ' }),
    i(5, 'name'),
    t(": InterfaceAccount<'info, Mint>,"),
  }),

  -- `prog` -> Program<'info, T> field (a custom program).
  s('prog', {
    t('pub '),
    i(1, 'name'),
    t(": Program<'info, "),
    i(2, 'Type'),
    t('>,'),
  }),

  -- `sys` -> the standard system_program field (fixed, no tab stops).
  s('sys', t("pub system_program: Program<'info, System>,")),

  -- `tprog` -> the token program interface field (fixed, no tab stops).
  s('tprog', t("pub token_program: Interface<'info, TokenInterface>,")),

  -- `hndl` -> Anchor instruction handler. The Context<...> type is a choice
  -- node populated from the #[derive(Accounts)] structs in this buffer (cycle
  -- with <C-f>; the last choice is free text). The stop right after Context<>
  -- is for extra args, e.g. `, amount: u64`; leave it empty for none.
  s('hndl', {
    t('pub fn '),
    i(1, 'handler'),
    t('(ctx: Context<'),
    d(2, ctx_node, {}),
    t('>'),
    i(3),
    t({ ') -> Result<()> {', '    ' }),
    i(0),
    t({ '', '    Ok(())', '}' }),
  }),

  -- `seed` -> seed byte-string constant. Type the byte-string name once
  -- (lowercase, by Rust convention); SEED_{} is auto-uppercased to match.
  s(
    'seed',
    fmt(
      'const SEED_{}: &[u8] = b"{}";',
      {
        f(function(args) return args[1][1]:upper() end, { 1 }),
        i(1, 'name'),
      }
    )
  ),
}
