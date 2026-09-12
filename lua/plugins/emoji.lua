-- emoji.nvim ships vim.ui.select, Telescope, and nvim-cmp frontends. This spec
-- uses none of them: it reads the plugin's emoji table and drives a Snacks
-- picker directly, so the glyph, name, slug, and group are all searchable.

---@return snacks.picker.finder.Item[]
local function emoji_items()
  local dir = require('lazy.core.config').plugins['emoji.nvim'].dir
  local emojis = require('emoji.emoji').load_emojis_from_json(dir .. '/lua/emoji/emojis2.json')
  local items = {}
  for _, e in ipairs(emojis) do
    items[#items + 1] = {
      text = table.concat({ e.character, e.unicode_name, e.slug, e.group, e.subgroup }, ' '),
      emoji = e,
    }
  end
  return items
end

local function pick_emoji()
  return Snacks.picker.pick {
    source = 'emoji',
    title = 'Emoji',
    items = emoji_items(),
    layout = { preset = 'select' },
    format = function(item)
      local e = item.emoji
      return {
        { e.character .. '  ' },
        { e.unicode_name },
        { '  ' .. e.group .. '/' .. e.subgroup, 'SnacksPickerComment' },
      }
    end,
    confirm = function(picker, item)
      picker:close()
      if item then
        require('emoji.utils').insert_string_at_current_cursor(item.emoji.character)
      end
    end,
  }
end

return {
  'allaman/emoji.nvim',
  version = '1.0.0',
  -- setup() only wires nvim-cmp, which this config replaced with blink.cmp,
  -- so the plugin is loaded for its data and insert helper alone.
  keys = {
    { '<leader>se', pick_emoji, desc = '[S]earch [E]moji' },
  },
}
