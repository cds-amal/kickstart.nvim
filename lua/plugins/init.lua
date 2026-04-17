-- Top-level specs in lua/plugins/ are auto-imported by lazy.nvim via
-- `{ import = 'plugins' }` in init.lua. Only subdirectories (like
-- languages/, which aggregates multiple specs) need to be required
-- explicitly from here.
return {
  require 'plugins.languages',
}
