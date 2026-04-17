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

## Requirements

- Neovim 0.12+
- `git`, `make`, `unzip`, a C compiler
- `ripgrep` (for Snacks.picker grep)
- Language-specific tools as needed (`go`, `npm`, etc.)
- A [Nerd Font](https://www.nerdfonts.com/) if you want icons; otherwise set
  `vim.g.have_nerd_font = false` in `lua/options.lua` (default).
