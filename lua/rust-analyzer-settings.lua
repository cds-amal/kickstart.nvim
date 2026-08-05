-- Settings for the rust-analyzer LSP server, as consumed by
-- `vim.g.rustaceanvim.server.settings['rust-analyzer']`.
--
-- Kept apart from the plugin spec because it is pure data: nothing here reads
-- editor state or runs at a particular time, so it has no reason to sit inside
-- a `config` function.

return {
  runnables = {
    -- Every test binary runs with --nocapture, which is what makes the
    -- quickfix test_executor worth having.
    extraTestBinaryArgs = { '--nocapture' },
  },

  completion = {
    callable = {
      snippets = 'fill_arguments',
    },
    postfix = {
      enable = true,
    },
  },

  cargo = {
    allFeatures = true,
    loadOutDirsFromCheck = true,
    runBuildScripts = true,
  },

  checkOnSave = true,
  check = {
    allFeatures = true,
    command = 'clippy',
    extraArgs = { '--no-deps' },
  },

  procMacro = {
    enable = true,
    -- Proc macros whose expansion rust-analyzer handles badly enough that the
    -- unexpanded form gives better completions and fewer phantom errors.
    ignored = {
      ['async-trait'] = { 'async_trait' },
      ['napi-derive'] = { 'napi' },
      ['async-recursion'] = { 'async_recursion' },
    },
  },

  diagnostics = {
    enable = true,
    experimental = {
      enable = false,
    },
  },

  inlayHints = {
    bindingModeHints = {
      enable = false,
    },
    chainingHints = {
      enable = true,
    },
    closingBraceHints = {
      enable = true,
      minLines = 25,
    },
    closureReturnTypeHints = {
      enable = 'with_block',
    },
    lifetimeElisionHints = {
      enable = 'never',
      useParameterNames = false,
    },
    maxLength = 25,
    parameterHints = {
      enable = true,
    },
    reborrowHints = {
      enable = 'never',
    },
    renderColons = true,
    typeHints = {
      enable = true,
      hideClosureInitialization = false,
      hideNamedConstructor = false,
    },
  },
}
