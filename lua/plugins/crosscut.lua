-- Local plugin: crosscut, the projection buffer for Rust APIs.
-- `:Crosscut typestate` and `impls` run the CLI on the package of the type under the
-- cursor; `roots` runs it over the whole workspace (about 8 s warm on surfpool, the first
-- open pays the build); `impls-lsp` needs only rust-analyzer. `lazy = false` keeps it eager even
-- though `keys` is set: the command and the cursor-following context (the scope color and
-- the breadcrumb segment) have to exist from startup, and the CLI is only spawned on use.
return {
  dir = '~/oss/mine/crosscut/editors/nvim',
  main = 'crosscut',
  lazy = false,
  opts = {
    bin = vim.fn.expand '~/oss/mine/crosscut/target/release/cargo-crosscut',
    open = 'vsplit',
  },
  keys = {
    { '<leader>rni', '<cmd>Crosscut impls<CR>', desc = 'Rust: navigate to [I]mpl projection' },
    { '<leader>rnt', '<cmd>Crosscut typestate<CR>', desc = 'Rust: navigate to [T]ypestate projection' },
    { '<leader>rnr', '<cmd>Crosscut roots<CR>', desc = 'Rust: navigate to the [R]oots list of the workspace' },
    { '<leader>rnl', '<cmd>Crosscut impls-lsp<CR>', desc = 'Rust: navigate to the impls projection from rust-analyzer ([L]SP)' },
    { '<leader>rng', '<cmd>Crosscut graph<CR>', desc = 'Rust: the typestate machine [G]raph, in a float over the source' },
  },
}
