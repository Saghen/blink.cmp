--- Manages most of the state for the completion list such that downstream consumers can be mostly stateless
--- @class (exact) blink.cmp.CompletionList
--- @field config blink.cmp.CompletionListConfig
--- @field context? blink.cmp.Context
--- @field items blink.cmp.CompletionItem[]
--- @field selected_item_idx? number
--- @field preview_undo? { text_edit: lsp.TextEdit, cursor: integer[]?}
--- @field show_emitter blink.cmp.EventEmitter<blink.cmp.CompletionListShowEvent>
--- @field hide_emitter blink.cmp.EventEmitter<blink.cmp.CompletionListHideEvent>
--- @field select_emitter blink.cmp.EventEmitter<blink.cmp.CompletionListSelectEvent>
--- @field accept_emitter blink.cmp.EventEmitter<blink.cmp.CompletionListAcceptEvent>
---
--- @field show fun(context: blink.cmp.Context, items: table<string, blink.cmp.CompletionItem[]>)
--- @field fuzzy fun(context: blink.cmp.Context, items: table<string, blink.cmp.CompletionItem[]>): blink.cmp.CompletionItem[]
--- @field hide fun()
---
--- @field get_selected_item fun(): blink.cmp.CompletionItem?
--- @field select fun(idx?: number, opts?: { undo_preview?: boolean, is_explicit_selection?: boolean })
--- @field select_next fun()
--- @field select_prev fun()
--- @field get_item_idx_in_list fun(item?: blink.cmp.CompletionItem): number
---
--- @field undo_preview fun()
--- @field apply_preview fun(item: blink.cmp.CompletionItem)
--- @field accept fun(opts?: blink.cmp.CompletionListAcceptOpts): boolean Applies the currently selected item, returning true if it succeeded

--- @class blink.cmp.CompletionListSelectAndAcceptOpts
--- @field callback? fun() Called after the item is accepted

--- @class blink.cmp.CompletionListAcceptOpts : blink.cmp.CompletionListSelectAndAcceptOpts
--- @field index? number The index of the item to accept, if not provided, the currently selected item will be accepted

--- @class blink.cmp.CompletionListShowEvent
--- @field items blink.cmp.CompletionItem[]
--- @field context blink.cmp.Context

--- @class blink.cmp.CompletionListHideEvent
--- @field context blink.cmp.Context

--- @class blink.cmp.CompletionListSelectEvent
--- @field idx? number
--- @field item? blink.cmp.CompletionItem
--- @field items blink.cmp.CompletionItem[]
--- @field context blink.cmp.Context

--- @class blink.cmp.CompletionListAcceptEvent
--- @field item blink.cmp.CompletionItem
--- @field context blink.cmp.Context

--- @type blink.cmp.CompletionList
--- @diagnostic disable-next-line: missing-fields
local list = {
  select_emitter = require('blink.cmp.lib.event_emitter').new('select', 'BlinkCmpListSelect'),
  accept_emitter = require('blink.cmp.lib.event_emitter').new('accept', 'BlinkCmpAccept'),
  show_emitter = require('blink.cmp.lib.event_emitter').new('show', 'BlinkCmpShow'),
  hide_emitter = require('blink.cmp.lib.event_emitter').new('hide', 'BlinkCmpHide'),
  config = require('blink.cmp.config').completion.list,
  context = nil,
  items = {},
  selected_item_idx = nil,
  is_explicitly_selected = false,
  preview_undo = nil,
}

---------- State ----------

function list.show(context, items_by_source)
  -- reset state for new context
  local is_new_context = not list.context or list.context.id ~= context.id
  if is_new_context then
    list.preview_undo = nil
    list.is_explicitly_selected = false
  end

  -- if the keyword changed, the list is no longer explicitly selected
  local bounds_equal = list.context ~= nil
    and list.context.bounds.start_col == context.bounds.start_col
    and list.context.bounds.length == context.bounds.length
  if not bounds_equal then list.is_explicitly_selected = false end

  local previous_selected_item = list.get_selected_item()

  -- update the context/list and emit
  list.context = context
  list.items = list.fuzzy(context, items_by_source)

  if #list.items == 0 then
    list.hide_emitter:emit({ context = context })
  else
    list.show_emitter:emit({ items = list.items, context = context })
  end

  -- maintain the selection if the user selected an item
  local previous_item_idx = list.get_item_idx_in_list(previous_selected_item)
  if list.is_explicitly_selected and previous_item_idx ~= nil and previous_item_idx <= 10 then
    list.select(previous_item_idx, { undo_preview = false })

  -- otherwise, use the default selection
  else
    list.select(
      list.config.selection == 'preselect' and 1 or nil,
      { undo_preview = false, is_explicit_selection = false }
    )
  end
end

function list.fuzzy(context, items_by_source)
  local fuzzy = require('blink.cmp.fuzzy')
  local filtered_items = fuzzy.fuzzy(context.get_keyword(), items_by_source)

  -- apply the per source max_items
  filtered_items = require('blink.cmp.sources.lib').apply_max_items_for_completions(context, filtered_items)

  -- apply the global max_items
  return require('blink.cmp.lib.utils').slice(filtered_items, 1, list.config.max_items)
end

function list.hide() list.hide_emitter:emit({ context = list.context }) end

---------- Selection ----------

function list.get_selected_item() return list.items[list.selected_item_idx] end

function list.select(idx, opts)
  opts = opts or {}
  local item = list.items[idx]

  require('blink.cmp.completion.trigger').suppress_events_for_callback(function()
    -- default to undoing the preview
    if opts.undo_preview ~= false then list.undo_preview() end
    if list.config.selection == 'auto_insert' and item then list.apply_preview(item) end
  end)

  --- @diagnostic disable-next-line: assign-type-mismatch
  list.is_explicitly_selected = opts.is_explicit_selection == nil and true or opts.is_explicit_selection
  list.selected_item_idx = idx
  list.select_emitter:emit({ idx = idx, item = item, items = list.items, context = list.context })
end

function list.select_next()
  if #list.items == 0 then return end

  -- haven't selected anything yet, select the first item
  if list.selected_item_idx == nil then return list.select(1) end

  -- end of the list
  if list.selected_item_idx == #list.items then
    -- cycling around has been disabled, ignore
    if not list.config.cycle.from_bottom then return end

    -- preselect is not enabled, we go back to no selection
    if list.config.selection ~= 'preselect' then return list.select(nil) end

    -- otherwise, we cycle around
    return list.select(1)
  end

  -- typical case, select the next item
  list.select(list.selected_item_idx + 1)
end

function list.select_prev()
  if #list.items == 0 then return end

  -- haven't selected anything yet, select the last item
  if list.selected_item_idx == nil then return list.select(#list.items) end

  -- start of the list
  if list.selected_item_idx == 1 then
    -- cycling around has been disabled, ignore
    if not list.config.cycle.from_top then return end

    -- auto_insert is enabled, we go back to no selection
    if list.config.selection == 'auto_insert' then return list.select(nil) end

    -- otherwise, we cycle around
    return list.select(#list.items)
  end

  -- typical case, select the previous item
  list.select(list.selected_item_idx - 1)
end

function list.get_item_idx_in_list(item)
  if item == nil then return end
  return require('blink.cmp.lib.utils').find_idx(list.items, function(i) return i.label == item.label end)
end

---------- Preview ----------

function list.undo_preview()
  if list.preview_undo == nil then return end

  require('blink.cmp.lib.text_edits').apply({ list.preview_undo.text_edit })
  if list.preview_undo.cursor then
    require('blink.cmp.completion.trigger.context').set_cursor(list.preview_undo.cursor)
  end
  list.preview_undo = nil
end

function list.apply_preview(item)
  -- undo the previous preview if it exists
  list.undo_preview()
  -- apply the new preview
  local undo_text_edit, undo_cursor = require('blink.cmp.completion.accept.preview')(item)
  list.preview_undo = { text_edit = undo_text_edit, cursor = undo_cursor }
end

---------- Accept ----------

function list.accept(opts)
  opts = opts or {}
  local item = list.items[opts.index or list.selected_item_idx]
  if item == nil then return false end

  list.undo_preview()
  local accept = require('blink.cmp.completion.accept')
  accept(list.context, item, function()
    list.accept_emitter:emit({ item = item, context = list.context })
    if opts.callback then opts.callback() end
  end)
  return true
end

return list
