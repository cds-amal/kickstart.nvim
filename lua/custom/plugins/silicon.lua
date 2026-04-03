return {
  "michaelrommel/nvim-silicon",
  cmd = "Silicon",
  config = function()
    require("silicon").setup({
      font = "JetBrainsMono Nerd Font=16",
      theme = "Monokai Extended Light",
      to_clipboard = true,
    })
  end,
}
