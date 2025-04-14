local golang = require 'custom.plugins.languages.golang'
local markdown = require 'custom.plugins.languages.markdown'

local language_plugins = {}

-- Add all items from golang table
for _, plugin in ipairs(golang) do
  table.insert(language_plugins, plugin)
end

-- Add all items from markdown table
for _, plugin in ipairs(markdown) do
  table.insert(language_plugins, plugin)
end

return language_plugins
