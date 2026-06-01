-- ftplugin/rust.lua
-- Rust-specific buffer-local keymaps.

local rust_utils = require('plugins.languages.rust-utils')

-- Toggle a macro call <-> its expansion under the cursor, in place:
--
--   ai!(ctx, asset)  <->  ctx.accounts.asset.to_account_info()
--
-- The transformation is derived from the macro's own macro_rules! definition,
-- fetched via rust-analyzer (textDocument/definition) and cached for the
-- session; a builtin copy of ai! covers the time before rust-analyzer is
-- ready. Works for any single-rule, ident-only macro; warns (and leaves the
-- buffer untouched) for anything it can't reverse exactly.
vim.keymap.set('n', '<leader>tai', rust_utils.toggle_ai, {
  buffer = true,
  desc = 'Toggle macro call <-> expansion (ai!, ...)',
})
