-- Local plugin: the typestate projection buffer from rs-typestate-viz.
-- `:RustProjection typestate` and `impls` run the CLI on the package of the type under the
-- cursor; `roots` runs it over the whole workspace (about 8 s warm on surfpool, the first
-- open pays the build); `impls-lsp` needs only rust-analyzer. `lazy = false` keeps it eager even
-- though `keys` is set: the command and the cursor-following context (the scope color and
-- the breadcrumb segment) have to exist from startup, and the CLI is only spawned on use.
return {
  dir = '~/oss/mine/rs-typestate-viz/editors/nvim',
  main = 'typestate',
  lazy = false,
  opts = {
    bin = vim.fn.expand '~/oss/mine/rs-typestate-viz/target/release/cargo-typestate-graph',
    open = 'vsplit',
  },
  keys = {
    { '<leader>rni', '<cmd>RustProjection impls<CR>', desc = 'Rust: navigate to [I]mpl projection' },
    { '<leader>rnt', '<cmd>RustProjection typestate<CR>', desc = 'Rust: navigate to [T]ypestate projection' },
    { '<leader>rnr', '<cmd>RustProjection roots<CR>', desc = 'Rust: navigate to the [R]oots list of the workspace' },
    { '<leader>rnl', '<cmd>RustProjection impls-lsp<CR>', desc = 'Rust: navigate to the impls projection from rust-analyzer ([L]SP)' },
  },
}
