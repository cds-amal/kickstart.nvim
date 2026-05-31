-- image.nvim: render real images inside Neovim. Used here as the display
-- backend for preview.nvim's `image_nvim` renderer (PlantUML -> PNG -> split).
--
-- Requirements on this machine: ghostty implements the kitty graphics protocol,
-- and we run inside tmux 3.6a with `allow-passthrough all` already set, so the
-- kitty backend works through tmux. ImageMagick must be installed for image
-- processing: `sudo pacman -S imagemagick` (we use the `magick` CLI via
-- processor = 'magick_cli', so no luarock/rocks.nvim build step is needed).
return {
  '3rd/image.nvim',
  ft = { 'plantuml' }, -- we only drive it through preview.nvim for now
  opts = {
    backend = 'kitty', -- ghostty speaks the kitty graphics protocol
    processor = 'magick_cli', -- shell out to the `magick` CLI, not the luarock
    -- We invoke image.nvim programmatically from preview.nvim's renderer, so
    -- leave the file-type auto-render integrations off (keeps it out of the
    -- way in markdown/html buffers).
    integrations = {
      markdown = { enabled = false },
      neorg = { enabled = false },
      typst = { enabled = false },
      html = { enabled = false },
      css = { enabled = false },
    },
  },
}
