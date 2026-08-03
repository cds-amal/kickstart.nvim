return {
  'mrcjkb/rustaceanvim',
  version = '^5',
  lazy = false,
  ft = { 'rust' },
  config = function()
    local codelldb_path = vim.fn.stdpath 'data' .. '/mason/bin/codelldb'
    local liblldb_ext = (vim.uv or vim.loop).os_uname().sysname == 'Darwin' and '.dylib' or '.so'
    local liblldb_path = vim.fn.stdpath 'data' .. '/mason/packages/codelldb/extension/lldb/lib/liblldb' .. liblldb_ext

    -- Resolve rustup's lldb helper scripts from the active toolchain so this
    -- works across machines/triples without hard-coding a target like
    -- `aarch64-apple-darwin`.
    local rust_sysroot = vim.fn.trim(vim.fn.system 'rustc --print sysroot')
    local rust_etc = rust_sysroot .. '/lib/rustlib/etc'

    -- LSP toggle state: 'rust-analyzer' or 'rs-commentary'
    vim.g.rust_lsp_active = 'rust-analyzer'

    local rs_commentary_path = vim.fn.expand '$HOME/oss/rs-commentary/target/release/rs-commentary'

    -- Start rs-commentary for a buffer
    local function start_rs_commentary(bufnr)
      bufnr = bufnr or vim.api.nvim_get_current_buf()
      vim.lsp.start {
        name = 'rs-commentary',
        cmd = { 'sh', '-c', rs_commentary_path .. ' 2>> /tmp/rs-commentary-log' },
        root_dir = vim.fs.root(bufnr, { 'Cargo.toml', '.git' }),
        capabilities = require('blink.cmp').get_lsp_capabilities(),
        on_attach = function()
          vim.lsp.inlay_hint.enable(true)
        end,
      }
    end

    -- Toggle function
    local function toggle_rust_lsp()
      local bufnr = vim.api.nvim_get_current_buf()

      -- Stop current LSP clients for this buffer
      local clients = vim.lsp.get_clients { bufnr = bufnr }
      for _, client in ipairs(clients) do
        if client.name == 'rust-analyzer' or client.name == 'rs-commentary' then
          client:stop()
        end
      end

      -- Toggle the active LSP
      if vim.g.rust_lsp_active == 'rust-analyzer' then
        vim.g.rust_lsp_active = 'rs-commentary'
        start_rs_commentary()
        vim.notify('Switched to rs-commentary', vim.log.levels.INFO)
      else
        vim.g.rust_lsp_active = 'rust-analyzer'
        -- Trigger FileType to let rustaceanvim auto-attach
        vim.cmd 'doautocmd FileType rust'
        vim.notify('Switched to rust-analyzer', vim.log.levels.INFO)
      end
    end

    -- Global keymap for toggling (works in any Rust buffer)
    vim.keymap.set('n', '<leader>rL', toggle_rust_lsp, { desc = 'Rust: Toggle LSP (rust-analyzer/rs-commentary)' })

    -- Auto-start rs-commentary for Rust files
    vim.api.nvim_create_autocmd('FileType', {
      pattern = 'rust',
      callback = function()
        if vim.g.rust_lsp_active == 'rs-commentary' then
          start_rs_commentary()
        end
      end,
    })

    -- Commands for rs-commentary
    vim.api.nvim_create_user_command('RsCommentaryStart', function()
      start_rs_commentary()
    end, {})

    vim.api.nvim_create_user_command('RsCommentaryStop', function()
      for _, client in ipairs(vim.lsp.get_clients { name = 'rs-commentary' }) do
        client:stop()
      end
    end, {})

    -- rust-analyzer only reports file:// links into target/doc (the cargo-doc
    -- generated pages, the only docs that exist for workspace crates) when the
    -- client advertises the experimental localDocs capability. With that on,
    -- the experimental/externalDocs response is { web?, local? } instead of a
    -- bare URL string, so open_url has to handle both shapes.
    local function open_docs_url(url)
      local open = require('rustaceanvim.os').open_url
      if type(url) == 'string' then
        open(url)
        return
      end
      local web, local_url = url.web, url['local']
      local local_path = local_url and vim.uri_to_fname(local_url:gsub('#.*$', ''))
      if local_path and vim.uv.fs_stat(local_path) then
        open(local_url)
      elseif web then
        open(web)
      elseif local_url then
        -- A workspace symbol whose docs haven't been generated yet: build
        -- them, then open. --no-deps keeps the build short enough to wait for.
        local root = vim.fs.root(0, 'Cargo.toml') or vim.fn.getcwd()
        vim.notify('Docs not generated yet; running cargo doc --no-deps ...', vim.log.levels.INFO)
        vim.system({ 'cargo', 'doc', '--no-deps' }, { cwd = root }, function(out)
          vim.schedule(function()
            if out.code == 0 then
              open(local_url)
            else
              vim.notify('cargo doc failed:\n' .. (out.stderr or ''), vim.log.levels.ERROR)
            end
          end)
        end)
      else
        vim.notify('No documentation found for the symbol under the cursor', vim.log.levels.WARN)
      end
    end

    vim.g.rustaceanvim = {
      -- Plugin configuration
      tools = {
        hover_actions = {
          auto_focus = false,
        },
        test_executor = 'quickfix', -- always populates quickfix with stdout+stderr; needed for --nocapture output
        open_url = open_docs_url,
      },

      -- LSP configuration
      server = {
        -- Merged over rustaceanvim's default capabilities; see open_docs_url.
        capabilities = {
          experimental = {
            localDocs = true,
          },
        },
        auto_attach = function()
          -- Only auto-attach rust-analyzer if it's the active LSP
          return vim.g.rust_lsp_active == 'rust-analyzer'
        end,
        on_attach = function(client, bufnr)
          -- Set keymaps for Rust-specific features
          local map = function(keys, func, desc)
            vim.keymap.set('n', keys, func, { buffer = bufnr, desc = 'Rust: ' .. desc })
          end

          -- Expand macro (with fallback to vim.pretty_print for inspection)
          map('<leader>re', function()
            vim.lsp.buf_request(bufnr, 'rust-analyzer/expandMacro', vim.lsp.util.make_position_params(0, client.offset_encoding), function(_, result)
              if not result or not result.expansion then
                vim.notify('No macro expansion available', vim.log.levels.WARN)
                return
              end

              -- Open right split with expanded macro
              vim.cmd 'vsplit'
              local buf = vim.api.nvim_create_buf(true, true)
              vim.api.nvim_win_set_buf(0, buf)
              local lines = vim.split(result.expansion, '\n')
              vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
              vim.api.nvim_buf_set_option(buf, 'filetype', 'rust')
              vim.api.nvim_buf_set_option(buf, 'modifiable', false)
            end)
          end, 'Expand Macro')

          -- Rust-specific keymaps
          map('<leader>rc', function()
            vim.cmd.RustLsp 'codeAction'
          end, 'Code Action')
          map('<leader>rd', function()
            vim.cmd.RustLsp 'debuggables'
          end, 'Debuggables')
          map('<leader>rt', function()
            vim.env.RUST_BACKTRACE = '1'
            vim.cmd.RustLsp 'testables'
          end, 'Testables')
          map('<leader>rr', function()
            vim.cmd.RustLsp 'runnables'
          end, 'Runnables')
          map('<leader>rp', function()
            vim.cmd.RustLsp 'rebuildProcMacros'
          end, 'Rebuild Proc Macros')
          map('<leader>rm', function()
            vim.cmd.RustLsp 'moveItemUp'
          end, 'Move Item Up')
          map('<leader>rM', function()
            vim.cmd.RustLsp 'moveItemDown'
          end, 'Move Item Down')
          map('<leader>rh', function()
            vim.cmd.RustLsp { 'hover', 'actions' }
          end, 'Hover Actions')
          map('<leader>rx', function()
            vim.cmd.RustLsp 'explainError'
          end, 'Explain Error')
          map('<leader>ro', function()
            vim.cmd.RustLsp 'openCargo'
          end, 'Open Cargo.toml')
          map('<leader>rg', function()
            vim.cmd.RustLsp 'openDocs'
          end, 'Open Docs')
          -- Alt+Click a symbol to open its docs in the browser. Alt rather
          -- than Ctrl: Ctrl+Click is already go-to-definition. The leading
          -- <LeftMouse> moves the cursor to the click target first.
          vim.keymap.set('n', '<M-LeftMouse>', '<LeftMouse><Cmd>RustLsp openDocs<CR>', { buffer = bufnr, desc = 'Rust: Open Docs (Alt+Click)' })
          map('<leader>rj', function()
            vim.cmd.RustLsp 'joinLines'
          end, 'Join Lines')

          -- Debug specific test under cursor
          map('<leader>rD', function()
            vim.cmd.RustLsp { 'debuggables', bang = true }
          end, 'Debug Test')

          -- Toggle inlay hints
          map('<leader>ri', function()
            vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled { bufnr = bufnr }, { bufnr = bufnr })
          end, 'Toggle Inlay Hints')
        end,

        settings = {
          ['rust-analyzer'] = {
            runnables = {
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
          },
        },
      },

      -- DAP configuration
      dap = {
        adapter = {
          type = 'server',
          port = '${port}',
          executable = {
            command = codelldb_path,
            args = { '--port', '${port}' },
          },
        },
        configuration = {
          initCommands = {
            'command script import ' .. rust_etc .. '/lldb_lookup.py',
            'command source ' .. rust_etc .. '/lldb_commands',
          },
        },
      },
    }
  end,
  dependencies = {
    'nvim-lua/plenary.nvim',
    'mfussenegger/nvim-dap',
  },
}
