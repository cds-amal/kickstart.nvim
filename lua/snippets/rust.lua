local ls = require('luasnip')
local s = ls.snippet
local i = ls.insert_node
local fmt = require('luasnip.extras.fmt').fmt
local fmta = require('luasnip.extras.fmt').fmta

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

  -- `pt` -> full proptest! { ... } block with one test
  s(
    'pt',
    fmt(
      [[
        proptest! {{
            #[test]
            fn {}({} in {}) {{
                {}
            }}
        }}
      ]],
      { i(1, 'prop_name'), i(2, 'x'), i(3, 'any::<u32>()'), i(0) }
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
}
