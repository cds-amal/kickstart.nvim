-- Local plugin: the typestate projection buffer from rs-typestate-viz.
-- `:RustProjection typestate` runs the CLI on the package of the type under the cursor;
-- `:RustProjection impls` needs only rust-analyzer. `lazy = false` keeps it eager even
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
  },
}
