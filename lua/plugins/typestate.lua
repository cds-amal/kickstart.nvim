-- Local plugin: the typestate projection buffer from rs-typestate-viz.
-- `:RustProjection typestate` runs the CLI on the package under the cursor's file;
-- `:RustProjection impls` needs only rust-analyzer. Eager-loaded so the command is
-- defined from startup; the CLI is only spawned on use.
return {
  dir = '~/oss/mine/rs-typestate-viz/editors/nvim',
  main = 'typestate',
  opts = {
    bin = vim.fn.expand('~/oss/mine/rs-typestate-viz/target/release/cargo-typestate-graph'),
    open = 'vsplit',
  },
}
