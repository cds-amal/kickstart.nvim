local golang = require 'plugins.languages.golang'
local markdown = require 'plugins.languages.markdown'
local tla = require 'plugins.languages.tla'

local language_plugins = {}

-- Add all items from golang table
for _, plugin in ipairs(golang) do
  table.insert(language_plugins, plugin)
end

-- Add all items from markdown table
for _, plugin in ipairs(markdown) do
  table.insert(language_plugins, plugin)
end

-- Add all items from tla table
for _, plugin in ipairs(tla) do
  table.insert(language_plugins, plugin)
end

return language_plugins
