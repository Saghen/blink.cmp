--- @class blink.cmp.API
local cmp = {
  list = require('blink.cmp.completion.list'),
  trigger = require('blink.cmp.completion.trigger'),
  menu = require('blink.cmp.completion.windows.menu'),
  ghost_text = require('blink.cmp.completion.windows.ghost_text'),
}

cmp.accept = cmp.list.accept
cmp.select_prev = cmp.list.select_prev
cmp.select_next = cmp.list.select_next
cmp.hide = cmp.trigger.hide

--- Show the completion window
--- @param opts? { providers?: string[], initial_selected_item_idx?: number }
function cmp.show(opts)
  cmp.menu.config({ auto_show = true }, { ephemeral = true })
  return cmp.trigger.show({
    force = true,
    providers = opts and opts.providers,
    trigger_kind = 'manual',
    initial_selected_item_idx = opts and opts.initial_selected_item_idx,
  })
end

--- Cancel the current completion, undoing the preview
function cmp.cancel()
  cmp.list.undo_preview()
  cmp.trigger.hide()
end

return cmp
