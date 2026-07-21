-- touchup.nvim: markdown decorator (chosen over render-markdown).
--
-- touchup overlays decorations without concealing or reflowing: dimmed syntax
-- markers instead of hidden ones, bullet icons by nesting depth, heading
-- underlines that keep the `#`, subtle code/quote backgrounds, and a smart
-- <CR> that continues/exits list items. Source columns stay honest (display
-- maps one-to-one to the bytes), which is the reason it won out here.
return {
  'noisesfromspace/touchup.nvim',
  ft = 'markdown',
  opts = {},
}
