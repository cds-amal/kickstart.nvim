-- Top-level specs in lua/custom/plugins/ are auto-imported by lazy.nvim
-- via `{ import = 'custom.plugins' }` in init.lua. Only subdirectories
-- (like languages/, which aggregates multiple specs) need to be required
-- explicitly from here.
return {
  require 'custom.plugins.languages',
}
