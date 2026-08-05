-- rs-commentary: a local LSP server that serves commentary on Rust code, run
-- as an alternative to rust-analyzer rather than alongside it. Only one of the
-- two is attached at a time, because both answer the same requests and having
-- both attached means every hover and completion arrives twice.
--
-- The choice lives in `vim.g.rust_lsp_active` ('rust-analyzer' | 'rs-commentary'),
-- which is the contract rustaceanvim's `server.auto_attach` reads: this module
-- is required after lazy.setup(), so that callback treats a nil value as
-- 'rust-analyzer' and works whether or not this file was loaded.

local M = {}

local SERVER = 'rs-commentary'
local DEFAULT = 'rust-analyzer'

local bin = vim.fn.expand '$HOME/oss/rs-commentary/target/release/rs-commentary'

vim.g.rust_lsp_active = vim.g.rust_lsp_active or DEFAULT

---Start rs-commentary for `bufnr` (default: the current buffer).
function M.start(bufnr)
  bufnr = bufnr or vim.api.nvim_get_current_buf()
  vim.lsp.start {
    name = SERVER,
    -- Wrapped in sh so the server's stderr lands somewhere readable; it is
    -- chatty on startup and would otherwise scroll past in :LspLog.
    cmd = { 'sh', '-c', bin .. ' 2>> /tmp/rs-commentary-log' },
    root_dir = vim.fs.root(bufnr, { 'Cargo.toml', '.git' }),
    capabilities = require('blink.cmp').get_lsp_capabilities(),
    on_attach = function()
      vim.lsp.inlay_hint.enable(true)
    end,
  }
end

function M.stop()
  for _, client in ipairs(vim.lsp.get_clients { name = SERVER }) do
    client:stop()
  end
end

---Swap which of the two servers is attached to the current buffer.
function M.toggle()
  for _, client in ipairs(vim.lsp.get_clients { bufnr = vim.api.nvim_get_current_buf() }) do
    if client.name == DEFAULT or client.name == SERVER then
      client:stop()
    end
  end

  if vim.g.rust_lsp_active == DEFAULT then
    vim.g.rust_lsp_active = SERVER
    M.start()
  else
    vim.g.rust_lsp_active = DEFAULT
    -- rustaceanvim attaches from its own FileType hook, so re-firing the
    -- event is how we ask it to reconsider this buffer.
    vim.cmd 'doautocmd FileType rust'
  end
  vim.notify('Switched to ' .. vim.g.rust_lsp_active, vim.log.levels.INFO)
end

vim.api.nvim_create_autocmd('FileType', {
  pattern = 'rust',
  callback = function(args)
    if vim.g.rust_lsp_active == SERVER then
      M.start(args.buf)
    end
  end,
})

vim.api.nvim_create_user_command('RsCommentaryStart', function()
  M.start()
end, { desc = 'Start the rs-commentary LSP server' })

vim.api.nvim_create_user_command('RsCommentaryStop', M.stop, { desc = 'Stop the rs-commentary LSP server' })

vim.keymap.set('n', '<leader>rL', M.toggle, { desc = 'Rust: Toggle LSP (rust-analyzer/rs-commentary)' })

return M
