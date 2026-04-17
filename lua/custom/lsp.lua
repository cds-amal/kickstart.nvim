-- LSP wiring: LspAttach keymaps/autocmds, diagnostic config, server list,
-- and mason installation. Called from the nvim-lspconfig plugin spec in
-- init.lua once mason + blink.cmp have loaded.
--
-- Picker bindings (grr/gri/grd/grs/grw/grt) go through Snacks.picker; see
-- lua/custom/plugins/snacks.lua.

local M = {}

-- Language servers to install and enable. `rust_analyzer` is deliberately
-- excluded here because rustaceanvim owns its lifecycle.
local servers = {
  gopls = {},

  jsonls = {
    settings = {
      json = {
        schemas = require('schemastore').json.schemas(),
        validate = { enable = true },
      },
    },
  },

  lua_ls = {
    settings = {
      Lua = {
        completion = { callSnippet = 'Replace' },
        -- diagnostics = { disable = { 'missing-fields' } }, -- silence noisy Lua_LS warnings
      },
    },
  },
}

-- Nvim 0.10 vs 0.11 API shim; can drop once 0.10 support is dropped.
local function client_supports_method(client, method, bufnr)
  if vim.fn.has 'nvim-0.11' == 1 then
    return client:supports_method(method, bufnr)
  end
  return client.supports_method(method, { bufnr = bufnr })
end

local function on_attach(event)
  local map = function(keys, func, desc, mode)
    mode = mode or 'n'
    vim.keymap.set(mode, keys, func, { buffer = event.buf, desc = 'LSP: ' .. desc })
  end

  map('grn', vim.lsp.buf.rename, '[R]e[n]ame')
  map('gra', vim.lsp.buf.code_action, '[G]oto Code [A]ction', { 'n', 'x' })
  map('grr', function() Snacks.picker.lsp_references() end, '[G]oto [R]eferences')
  map('gri', function() Snacks.picker.lsp_implementations() end, '[G]oto [I]mplementation')
  map('grd', function() Snacks.picker.lsp_definitions() end, '[G]oto [D]efinition')
  map('grD', vim.lsp.buf.declaration, '[G]oto [D]eclaration')
  map('grs', function() Snacks.picker.lsp_symbols() end, '[S]ymbols (document)')
  map('grw', function() Snacks.picker.lsp_workspace_symbols() end, '[W]orkspace symbols')
  map('grt', function() Snacks.picker.lsp_type_definitions() end, '[G]oto [T]ype Definition')
  map('<C-s>', vim.lsp.buf.signature_help, 'Signature Help', 'i')

  local client = vim.lsp.get_client_by_id(event.data.client_id)
  if client and client_supports_method(client, vim.lsp.protocol.Methods.textDocument_inlayHint, event.buf) then
    map('<leader>th', function()
      vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled { bufnr = event.buf })
    end, '[T]oggle Inlay [H]ints')
  end

  -- Reposition diagnostic floats to the top-right so they don't overlap
  -- the cursor's column. CursorHold fires globally; configured here per-attach.
  vim.api.nvim_create_autocmd('CursorHold', {
    callback = function()
      local _, win = vim.diagnostic.open_float(nil, { focusable = false, source = 'if_many' })
      if not win then return end

      local cfg = vim.api.nvim_win_get_config(win)
      cfg.anchor = 'NE'
      cfg.row = 0
      cfg.col = vim.o.columns - 1
      cfg.width = math.min(cfg.width or 999, math.floor(vim.o.columns * 0.6))
      cfg.height = math.min(cfg.height or 999, math.floor(vim.o.lines * 0.4))
      vim.api.nvim_win_set_config(win, cfg)
    end,
  })
end

function M.setup()
  vim.api.nvim_create_autocmd('LspAttach', {
    group = vim.api.nvim_create_augroup('custom-lsp-attach', { clear = true }),
    callback = on_attach,
  })

  vim.diagnostic.config {
    severity_sort = true,
    float = { border = 'rounded', source = 'if_many' },
    underline = { severity = vim.diagnostic.severity.ERROR },
    signs = vim.g.have_nerd_font and {
      text = {
        [vim.diagnostic.severity.ERROR] = '󰅚 ',
        [vim.diagnostic.severity.WARN] = '󰀪 ',
        [vim.diagnostic.severity.INFO] = '󰋽 ',
        [vim.diagnostic.severity.HINT] = '󰌶 ',
      },
    } or {},
    virtual_text = false, -- inline messages off; use Trouble or float instead
  }

  local capabilities = require('blink.cmp').get_lsp_capabilities()

  local ensure_installed = vim.tbl_keys(servers)
  vim.list_extend(ensure_installed, { 'stylua' })
  require('mason-tool-installer').setup { ensure_installed = ensure_installed }

  require('mason-lspconfig').setup {
    ensure_installed = {}, -- mason-tool-installer drives installs
    automatic_installation = true,
    automatic_enable = {
      exclude = { 'rust_analyzer' }, -- rustaceanvim owns this
    },
    handlers = {
      function(server_name)
        local server = servers[server_name] or {}
        server.capabilities = vim.tbl_deep_extend('force', {}, capabilities, server.capabilities or {})
        require('lspconfig')[server_name].setup(server)
      end,
    },
  }
end

return M
