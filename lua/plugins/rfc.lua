-- Local plugin: rfc.nvim, RFCs, Ethereum's EIPs and ERCs, Bitcoin's BIPs and Solana's SIMDs as Neovim help.
-- `:Rfc 9110`, `:Eip 20`, `:Bip 32` or `:Simd 64` fetches the document (EIPs and ERCs are one number space) and opens
-- it with :help; from there CTRL-], CTRL-T and :helpgrep are the interface. Loaded eagerly: setup() puts the cache directory on the
-- runtimepath so `:help rfc9110` works in a fresh session, and the plugin's
-- FileType autocmd attaches the fetch-on-E149 keys to its help buffers.
return {
  dir = '~/dev/nvim-plugins/rfc.nvim',
  main = 'rfc',
  lazy = false,
  opts = {
    sources = { rfc = true, eip = true, bip = true, simd = true, w3c = true },
    -- Every rfc message goes through this, as calplus's do: snacks toasts float, so
    -- they leave cmdheight alone.
    notify = function(msg, level, opts)
      require('snacks').notifier.notify(msg, level, opts)
    end,
  },
}
