;; extends

; Claude Code prompt buffers only (see the claudeprompt? predicate in
; lua/plugins/treesitter.lua): the section bodies of the <prompt> skeleton
; are html text nodes, and they are written as markdown.
((text) @injection.content
  (#claudeprompt? @injection.content)
  (#set! injection.language "markdown"))
