return {
  "michaelrommel/nvim-silicon",
  cmd = "Silicon",
  config = function()
    require("silicon").setup({
      -- Fallback chain (separated by ";"): the Nerd Font has no real emoji
      -- codepoints, so a fallback covers characters like 🔔 (U+1F514).
      -- N.B. use the MONOCHROME "Noto Emoji", not "Noto Color Emoji": silicon
      -- 0.5.2 (font-kit/freetype) cannot rasterize color-glyph tables, so color
      -- emoji fonts render blank (and "Apple Color Emoji" crashes silicon).
      -- Monochrome outline glyphs render fine, tinted to the syntax color.
      font = "JetBrainsMono Nerd Font=16;Noto Emoji=16",
      theme = "Monokai Extended Light",
      to_clipboard = true,
    })
  end,
}
