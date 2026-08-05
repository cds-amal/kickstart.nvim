-- lazy = false, and no `ft`: rustaceanvim installs its own FileType hook and
-- asks not to be lazy-loaded. An `ft` trigger here would be inert anyway, since
-- lazy.nvim only infers laziness from triggers when `lazy` is unset.
return {
  'mrcjkb/rustaceanvim',
  version = '^5',
  lazy = false,
  config = function()
    -- Every cargo process nvim spawns gets backtraces, which is what we want
    -- from the test runner and harmless everywhere else.
    vim.env.RUST_BACKTRACE = '1'

    -- Resolve rustup's lldb helper scripts from the active toolchain so this
    -- works across machines/triples without hard-coding a target like
    -- `aarch64-apple-darwin`.
    local rust_etc = vim.fn.trim(vim.fn.system 'rustc --print sysroot') .. '/lib/rustlib/etc'

    -- Workspace members as { doc_directory_name = package_name }. cargo turns
    -- hyphens into underscores for the doc directory (surfpool-types becomes
    -- surfpool_types), and we need the round trip back: a doc path tells us
    -- which crate to name in `cargo doc -p`.
    --
    -- `cargo metadata --no-deps` only reads manifests, so it costs ~50ms on a
    -- nine-member workspace, is cached for the session, and is reached only
    -- when a local doc page turned out to be missing.
    local members_by_root = {}
    local function workspace_members(root)
      if not members_by_root[root] then
        local members = {}
        local out = vim.system({ 'cargo', 'metadata', '--no-deps', '--format-version', '1' }, { cwd = root, text = true }):wait()
        local ok, meta = pcall(vim.json.decode, out.stdout or '')
        if out.code == 0 and ok then
          for _, pkg in ipairs(meta.packages or {}) do
            members[(pkg.name:gsub('%-', '_'))] = pkg.name
          end
        end
        members_by_root[root] = members
      end
      return members_by_root[root]
    end

    -- rust-analyzer only reports file:// links into target/doc (the cargo-doc
    -- generated pages, the only docs that exist for workspace crates) when the
    -- client advertises the experimental localDocs capability. With that on,
    -- the experimental/externalDocs response is { web?, local? } instead of a
    -- bare URL string, so open_url has to handle both shapes.
    --
    -- It fills in `web` for everything, workspace crates included, so treating
    -- web as the fallback whenever the local page is missing would mean the
    -- page never gets built: you would land on a docs.rs URL that is stale for
    -- a workspace crate and absent for an unpublished one. Preference order is
    -- therefore the local page, then building it when the crate is one of ours
    -- (--no-deps builds workspace members and nothing else, so there is no
    -- point running it for a dependency), then docs.rs.
    local function open_docs_url(url)
      local open = require('rustaceanvim.os').open_url
      if type(url) == 'string' then
        open(url)
        return
      end

      -- rust-analyzer sends JSON null for a half it cannot resolve, and that
      -- decodes to vim.NIL, which is truthy in Lua. Testing the type rather
      -- than truthiness is what keeps `local_url:gsub` from indexing userdata.
      local web = type(url.web) == 'string' and url.web or nil
      local local_url = type(url['local']) == 'string' and url['local'] or nil

      local local_path = local_url and vim.uri_to_fname(local_url:gsub('#.*$', ''))
      if local_path and vim.uv.fs_stat(local_path) then
        open(local_url)
        return
      end

      -- The local URL carries both halves we need: <root>/target/doc/<crate>/...
      local root, crate = nil, nil
      if local_path then
        root, crate = local_path:match '^(.*)/target/doc/([^/]+)/'
      end

      -- Scoped with -p: at a virtual workspace root, a bare `cargo doc` documents
      -- every member and compiles the whole dependency tree with it, which for a
      -- nine-crate Solana workspace is minutes. One crate is seconds.
      local package = root and workspace_members(root)[crate] or nil
      if package then
        vim.notify(('Docs for %s not built yet; running cargo doc -p %s ...'):format(crate, package), vim.log.levels.INFO)
        vim.system({ 'cargo', 'doc', '--no-deps', '-p', package }, { cwd = root }, function(out)
          vim.schedule(function()
            if out.code == 0 and vim.uv.fs_stat(local_path) then
              open(local_url)
            elseif out.code ~= 0 then
              vim.notify('cargo doc failed:\n' .. (out.stderr or ''), vim.log.levels.ERROR)
            elseif web then
              -- Built fine, but the item has no page of its own (a re-export,
              -- say). docs.rs is a better guess than a 404 on disk.
              open(web)
            else
              vim.notify('cargo doc built no page for this symbol', vim.log.levels.WARN)
            end
          end)
        end)
        return
      end

      if web then
        open(web)
      else
        vim.notify('No documentation found for the symbol under the cursor', vim.log.levels.WARN)
      end
    end

    -- Matches rustaceanvim's own is_testable: rust-analyzer labels a runnable
    -- as a test by its first cargo arg, which covers `test` and `test-mod`.
    local function is_testable(runnable)
      local cargo_args = runnable.args and runnable.args.cargoArgs or {}
      return #cargo_args > 0 and vim.startswith(cargo_args[1], 'test')
    end

    -- rustaceanvim gives us two halves of what ,rt should do: `run` resolves
    -- the runnable at the cursor but doesn't care whether it's a test (in
    -- `fn main` it would cheerfully `cargo run`), and `testables` filters to
    -- tests but always prompts. Filtering to testables *before* the cursor
    -- lookup gives both: an exact hit runs, anything else falls through to
    -- the picker.
    local function test_at_cursor()
      local params = {
        textDocument = vim.lsp.util.make_text_document_params(0),
        position = nil, -- ask for every runnable; we do our own cursor filtering
      }
      vim.lsp.buf_request(0, 'experimental/runnables', params, function(_, result)
        local runnables = require('rustaceanvim.runnables')
        local testables = vim.tbl_filter(is_testable, result or {})
        -- get_runnable_at_cursor_position prefers a specific test over the
        -- enclosing test-mod, so this only picks the module when the cursor
        -- sits between test functions.
        local choice = #testables > 0 and runnables.get_runnable_at_cursor_position(testables) or nil
        if not choice then
          vim.cmd.RustLsp 'testables'
          return
        end
        runnables.run_command(choice, testables)
        local cached = require('rustaceanvim.cached_commands')
        cached.set_last_testable(choice, testables)
        cached.set_last_runnable(choice, testables)
      end)
    end

    -- Open the macro expansion under the cursor in a scratch split.
    local function expand_macro(client, bufnr)
      local position = vim.lsp.util.make_position_params(0, client.offset_encoding)
      vim.lsp.buf_request(bufnr, 'rust-analyzer/expandMacro', position, function(_, result)
        if not result or not result.expansion then
          vim.notify('No macro expansion available', vim.log.levels.WARN)
          return
        end
        vim.cmd 'vsplit'
        local buf = vim.api.nvim_create_buf(true, true)
        vim.api.nvim_win_set_buf(0, buf)
        vim.api.nvim_buf_set_lines(buf, 0, -1, false, vim.split(result.expansion, '\n'))
        vim.bo[buf].filetype = 'rust'
        vim.bo[buf].modifiable = false
      end)
    end

    -- Keymaps that are nothing but a RustLsp subcommand, as { suffix, cmd, desc }.
    -- `cmd` is passed to vim.cmd.RustLsp as-is, so a table carries extra args
    -- or a bang the same way it would on the command line.
    local RUSTLSP_MAPS = {
      { 'rc', 'codeAction', 'Code Action' },
      { 'rd', 'debuggables', 'Debuggables' },
      { 'rr', 'runnables', 'Runnables' },
      { 'rT', 'testables', 'Testables (pick)' },
      { 'rp', 'rebuildProcMacros', 'Rebuild Proc Macros' },
      { 'rm', 'moveItemUp', 'Move Item Up' },
      { 'rM', 'moveItemDown', 'Move Item Down' },
      { 'rx', 'explainError', 'Explain Error' },
      { 'ro', 'openCargo', 'Open Cargo.toml' },
      { 'rg', 'openDocs', 'Open Docs' },
      { 'rj', 'joinLines', 'Join Lines' },
      { 'rh', { 'hover', 'actions' }, 'Hover Actions' },
      { 'r.', { 'run', bang = true }, 'Rerun Last' },
      { 'rD', { 'debuggables', bang = true }, 'Debug Test at Cursor' },
    }

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
          -- rs-commentary answers the same requests, so only one of the two
          -- attaches; nil means it was never loaded. See lua/rs-commentary.lua.
          return (vim.g.rust_lsp_active or 'rust-analyzer') == 'rust-analyzer'
        end,
        on_attach = function(client, bufnr)
          local function map(keys, func, desc)
            vim.keymap.set('n', keys, func, { buffer = bufnr, desc = 'Rust: ' .. desc })
          end

          for _, entry in ipairs(RUSTLSP_MAPS) do
            local suffix, cmd, desc = entry[1], entry[2], entry[3]
            map('<leader>' .. suffix, function()
              vim.cmd.RustLsp(cmd)
            end, desc)
          end

          map('<leader>re', function()
            expand_macro(client, bufnr)
          end, 'Expand Macro')
          map('<leader>rt', test_at_cursor, 'Test at Cursor')
          map('<leader>ri', function()
            vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled { bufnr = bufnr }, { bufnr = bufnr })
          end, 'Toggle Inlay Hints')

          -- Alt+Click a symbol to open its docs in the browser. Alt rather
          -- than Ctrl: Ctrl+Click is already go-to-definition. The leading
          -- <LeftMouse> moves the cursor to the click target first.
          map('<M-LeftMouse>', '<LeftMouse><Cmd>RustLsp openDocs<CR>', 'Open Docs (Alt+Click)')
        end,

        settings = {
          ['rust-analyzer'] = require 'rust-analyzer-settings',
        },
      },

      -- DAP configuration
      dap = {
        adapter = {
          type = 'server',
          port = '${port}',
          executable = {
            command = vim.fn.stdpath 'data' .. '/mason/bin/codelldb',
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
