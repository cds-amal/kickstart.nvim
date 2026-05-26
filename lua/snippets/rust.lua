local ls = require('luasnip')
local s = ls.snippet
local i = ls.insert_node
local t = ls.text_node
local f = ls.function_node
local fmt = require('luasnip.extras.fmt').fmt
local fmta = require('luasnip.extras.fmt').fmta
local rep = require('luasnip.extras').rep

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

  -- `acc` -> #[derive(Accounts)] struct skeleton
  s(
    'acc',
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

  -- `inst` -> #[instruction(...)] attribute
  s(
    'inst',
    fmt('#[instruction({})]', { i(1, 'arg: Type') })
  ),

  -- `iximpl` -> impl block with handler returning Result<()>
  s(
    'iximpl',
    fmt(
      [[
        impl<'info> {}<'info> {{
            pub fn {}(&mut self, {}) -> Result<()> {{
                {}
                Ok(())
            }}
        }}
      ]],
      { i(1, 'Name'), i(2, 'handler'), i(3), i(0) }
    )
  ),

  -- `signer` -> mutable signer account
  s(
    'signer',
    t({ '#[account(mut)]', 'pub signer: Signer<\'info>,' })
  ),

  -- `pda` -> mutable PDA account (one tab stop for seeds)
  s(
    'pda',
    fmt(
      [[
        #[account(
            mut,
            seeds = [{}],
            bump,
        )]
        pub {}: Account<'info, {}>,
      ]],
      { i(1, 'SEED'), i(2, 'name'), i(3, 'Type') }
    )
  ),

  -- `init` -> init account (payer/space/seeds/bump). Type is linked.
  s(
    'init',
    fmt(
      [[
        #[account(
            init,
            payer = {},
            space = 8 + {}::INIT_SPACE,
            seeds = [{}],
            bump,
        )]
        pub {}: Account<'info, {}>,
      ]],
      { i(1, 'signer'), i(2, 'Type'), i(3, 'SEED'), i(4, 'name'), rep(2) }
    )
  ),

  -- `sysprog` -> system program field
  s('sysprog', t('pub system_program: Program<\'info, System>,')),

  -- `acct` -> bare Account field (no constraints)
  s(
    'acct',
    fmt('pub {}: Account<\'info, {}>,', { i(1, 'name'), i(2, 'Type') })
  ),

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

  -- `litesvm` -> anchor_litesvm BundledPubkeys cfg_attr (project-specific)
  s(
    'litesvm',
    fmt(
      [[
        #[cfg_attr(
            not(target_os = "solana"),
            derive(anchor_litesvm::BundledPubkeys),
            bundled_with(crate::test_helpers::{})
        )]
      ]],
      { i(1, 'Bundle') }
    )
  ),
}
