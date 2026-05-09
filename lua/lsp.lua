-- LSP wiring: LspAttach keymaps/autocmds, diagnostic config, server list,
-- and mason installation. Called from the nvim-lspconfig plugin spec in
-- init.lua once mason + blink.cmp have loaded.
--
-- Picker bindings (grr/gri/grd/grs/grw/grt) go through Snacks.picker; see
-- lua/plugins/snacks.lua.

local M = {}

-- Language servers to install and enable. `rust_analyzer` is deliberately
-- excluded here because rustaceanvim owns its lifecycle.
local servers = {
  cssls = {},

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

  vtsls = {
    settings = {
      typescript = {
        inlayHints = {
          parameterNames = { enabled = 'literals' },
          parameterTypes = { enabled = true },
          variableTypes = { enabled = true },
          propertyDeclarationTypes = { enabled = true },
          functionLikeReturnTypes = { enabled = true },
          enumMemberValues = { enabled = true },
        },
      },
      javascript = {
        inlayHints = {
          parameterNames = { enabled = 'literals' },
          parameterTypes = { enabled = true },
          variableTypes = { enabled = true },
          propertyDeclarationTypes = { enabled = true },
          functionLikeReturnTypes = { enabled = true },
        },
      },
    },
  },
}

-- Follow a markdown `file://` link inside an LSP hover float, in place.
-- Parses links of the form `[text](file:///path#L<line>%2C<col>)` (the format
-- vtsls and other typescript servers emit), URL-decodes the path so pnpm-style
-- `%40` segments resolve, then `:edit`s the target in the same float window.
-- Setting `bufhidden=hide` on the hover buffer keeps it alive after the buffer
-- switch so `<C-o>` (jumplist) can come back to it; `:edit` itself adds the
-- leave-position to the jumplist automatically.
-- Find the first markdown link `[text](url)` whose range contains `col` on
-- `line`. Returns `{ s, e, text, url }` or nil. vim.iter:find short-circuits
-- on the first match.
local function find_link_at(line, col)
  local pos = 1
  return vim.iter(function()
    local s, e, text, url = line:find('%[([^%]]+)%]%(([^)]+)%)', pos)
    if not s then return nil end
    pos = e + 1
    return { s = s, e = e, text = text, url = url }
  end):find(function(l) return col >= l.s and col <= l.e end)
end

-- Forward declaration so edit_in_place can reference follow_lsp_definition
-- when re-binding <C-]> on the destination buffer.
local follow_lsp_definition

-- Edit `path` in the current window using the in-place navigation pattern:
-- `bufhidden=hide` keeps the outgoing buffer alive so `<C-o>` can return to
-- it, `:edit` records the leave-position in the jumplist, and we re-bind
-- `<C-]>` on the destination buffer to follow_lsp_definition so the chain
-- can continue (markdown link → .d.ts → {@link X} → another .d.ts → ...).
local function edit_in_place(path, lnum, cnum)
  vim.bo.bufhidden = 'hide'
  vim.cmd.edit(path)
  if lnum then
    pcall(vim.api.nvim_win_set_cursor, 0, { lnum, (cnum or 1) - 1 })
  end
  vim.keymap.set('n', '<C-]>', function() follow_lsp_definition() end, {
    buffer = 0,
    desc = 'LSP: follow definition in place (chained)',
  })
end

-- Ask the LSP for the definition of the symbol under cursor, then jump there
-- via edit_in_place. Used inside the doc-browser float to follow `{@link X}`
-- references and other in-source identifiers.
follow_lsp_definition = function()
  local clients = vim.lsp.get_clients { bufnr = 0, method = 'textDocument/definition' }
  if #clients == 0 then
    vim.notify('No LSP for definition under cursor', vim.log.levels.WARN)
    return
  end
  local params = vim.lsp.util.make_position_params(0, clients[1].offset_encoding or 'utf-16')
  vim.lsp.buf_request(0, 'textDocument/definition', params, function(err, result)
    if err or not result or (type(result) == 'table' and vim.tbl_isempty(result)) then
      vim.notify('No definition under cursor', vim.log.levels.WARN)
      return
    end
    local loc = vim.islist(result) and result[1] or result
    local uri = loc.uri or loc.targetUri
    local range = loc.range or loc.targetSelectionRange
    edit_in_place(vim.uri_to_fname(uri), range.start.line + 1, range.start.character + 1)
  end)
end

local function follow_hover_link()
  local link = find_link_at(
    vim.api.nvim_get_current_line(),
    vim.api.nvim_win_get_cursor(0)[2] + 1
  )
  if not link then
    vim.notify('No link under cursor', vim.log.levels.WARN)
    return
  end

  local url = link.url
  if url:match('^file://') then
    local path = vim.uri_decode(url:match('^file://([^#]+)'))
    local lnum = tonumber(url:match('#L(%d+)')) or 1
    local cnum = tonumber(url:match('#L%d+%%2C(%d+)') or url:match('#L%d+,(%d+)')) or 1
    edit_in_place(path, lnum, cnum)
  elseif url:match('^https?://') then
    require('url-opener').open(url)
  else
    vim.notify('Unsupported scheme: ' .. url, vim.log.levels.INFO)
  end
end

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

  if client and client_supports_method(client, vim.lsp.protocol.Methods.textDocument_documentColor, event.buf) then
    vim.lsp.document_color.enable(true, { bufnr = event.buf }, { style = 'virtual' })
    map('<leader>tc', function()
      vim.lsp.document_color.enable(not vim.lsp.document_color.is_enabled { bufnr = event.buf }, { bufnr = event.buf }, { style = 'virtual' })
    end, '[T]oggle [C]olor previews')
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

  -- Make file:// links inside LSP hover floats navigable. We hook FileType
  -- (not BufWinEnter): vim.lsp.util.open_floating_preview sets filetype only
  -- after the window opens, so BufWinEnter fires too early. By the time
  -- FileType=markdown fires, the buffer is already buftype=nofile, so that
  -- check is enough to filter out user-opened markdown files.
  vim.api.nvim_create_autocmd('FileType', {
    group = vim.api.nvim_create_augroup('lsp-hover-links', { clear = true }),
    pattern = 'markdown',
    callback = function(args)
      if vim.bo[args.buf].buftype == 'nofile' then
        vim.keymap.set('n', '<C-]>', follow_hover_link, {
          buffer = args.buf,
          desc = 'LSP: follow file:// link in hover',
        })
      end
    end,
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
