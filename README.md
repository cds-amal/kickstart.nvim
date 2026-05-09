# nvim

Personal Neovim configuration. Started from kickstart.nvim and has since
diverged: no kickstart namespace, no Telescope, picker and UI consolidated on
[folke/snacks.nvim](https://github.com/folke/snacks.nvim), LSP config factored
out of `init.lua`, etc.

Layout:

- `init.lua` — leader keys, loads options, boots lazy.nvim, wires a few
  top-level autocommands, requires the helper modules at the bottom.
- `lua/options.lua` — editor options and filetype-specific overrides.
- `lua/lsp.lua` — LSP wiring (LspAttach keymaps, diagnostic config, mason,
  server list). Invoked from the `nvim-lspconfig` plugin spec.
- `lua/keymaps.lua` — general keymaps (fuzzy finders, indent-aware paste, etc.).
- `lua/plugins/` — one lazy.nvim spec per file; `{ import = 'plugins' }`
  picks them up in `init.lua`.
- `lua/plugins/languages/` — aggregates multi-spec language configs.
- `lua/<module>.lua` — non-plugin utility modules (git-commit, messages,
  multigrep, truth-table-core, etc.).
- `ftplugin/<ft>.lua` — filetype-specific buffer setup (cue, zsh).
- `tests/` — plain Lua tests for utility modules.

Leader: `,` · Local leader: `\`

See `CLAUDE.md` for more detail on conventions and the reasoning behind the
layout.

## Hover as doc browser

`K` opens an LSP hover. `K` again focuses the float (this also strips nvim's
auto-close-on-buffer-swap autocmds, so the float survives navigation).
Inside the focused float, `<C-]>` follows references in place:

- Markdown `[text](file:///path#L<line>%2C<col>)` link (vtsls and other TS
  servers emit these for cross-references): edits the target in the same
  float window.
- Any other identifier (e.g. `KeyPairSigner` inside `{@link}`): asks the LSP
  for a definition, edits that in place.
- `https?://` link: delegates to `xdg-open` / `open` / `cmd.exe start` via
  `lua/url-opener.lua`.

The float's per-window jumplist tracks the chain, so `<C-o>` and `<C-i>`
walk every navigation back and forward. `:q` dismisses the whole stack.

`KK` (not just one `K`) is required before chaining: without the focus step
nvim's lifecycle autocmds close the float on the first buffer swap.

Implementation: `lua/lsp.lua` (`follow_hover_link`, `edit_in_place`,
`follow_lsp_definition`); the `FileType=markdown` autocmd in `M.setup()`
installs the buffer-local `<C-]>` on hover floats.

## Requirements

- Neovim 0.12+
- `git`, `make`, `unzip`, a C compiler
- `ripgrep` (for Snacks.picker grep)
- Language-specific tools as needed (`go`, `npm`, etc.)
- A [Nerd Font](https://www.nerdfonts.com/) if you want icons; otherwise set
  `vim.g.have_nerd_font = false` in `lua/options.lua` (default).
