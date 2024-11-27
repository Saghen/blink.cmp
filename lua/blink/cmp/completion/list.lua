--- Manages most of the state for the completion list such that downstream consumers can be mostly stateless
--- @class (exact) blink.cmp.CompletionList
--- @field config blink.cmp.CompletionListConfig
--- @field context? blink.cmp.Context
--- @field items blink.cmp.CompletionItem[]
--- @field selected_item_idx? number
--- @field preview_undo_text_edit? lsp.TextEdit
--- @field show_emitter blink.cmp.EventEmitter<blink.cmp.CompletionListShowEvent>
--- @field hide_emitter blink.cmp.EventEmitter<blink.cmp.CompletionListHideEvent>
--- @field select_emitter blink.cmp.EventEmitter<blink.cmp.CompletionListSelectEvent>
--- @field accept_emitter blink.cmp.EventEmitter<blink.cmp.CompletionListAcceptEvent>
---
--- @field show fun(context: blink.cmp.Context, items?: blink.cmp.CompletionItem[])
--- @field fuzzy fun(context: blink.cmp.Context, items: blink.cmp.CompletionItem[]): blink.cmp.CompletionItem[]
--- @field hide fun()
---
--- @field get_selected_item fun(): blink.cmp.CompletionItem?
--- @field select fun(idx?: number)
--- @field select_next fun()
--- @field select_prev fun()
---
--- @field undo_preview fun()
--- @field apply_preview fun(item: blink.cmp.CompletionItem)
--- @field accept fun(): boolean Applies the currently selected item, returning true if it succeeded

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
  preview_undo_text_edit = nil,
}

---------- State ----------

function list.show(context, items)
  -- reset state for new context
  local is_new_context = not list.context or list.context.id ~= context.id
  if is_new_context then list.preview_undo_text_edit = nil end

  list.context = context
  list.items = list.fuzzy(context, items or list.items)

  if #list.items == 0 then
    list.hide_emitter:emit({ context = context })
  else
    list.show_emitter:emit({ items = list.items, context = context })
  end

  -- todo: some logic to maintain the selection if the user moved the cursor?
  list.select(list.config.selection == 'preselect' and 1 or nil)
end

function list.fuzzy(context, items)
  local fuzzy = require('blink.cmp.fuzzy')
  local sources = require('blink.cmp.sources.lib')

  local filtered_items = fuzzy.fuzzy(fuzzy.get_query(), items)
  return sources.apply_max_items_for_completions(context, filtered_items)
end

function list.hide() list.hide_emitter:emit({ context = list.context }) end

---------- Selection ----------

function list.get_selected_item() return list.items[list.selected_item_idx] end

function list.select(idx)
  local item = list.items[idx]

  list.undo_preview()
  if list.config.selection == 'auto_insert' and item then list.apply_preview(item) end

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

---------- Preview ----------

function list.undo_preview()
  if list.preview_undo_text_edit == nil then return end

  require('blink.cmp.lib.text_edits').apply({ list.preview_undo_text_edit })
  list.preview_undo_text_edit = nil
end

function list.apply_preview(item)
  require('blink.cmp.completion.trigger').suppress_events_for_callback(function()
    -- undo the previous preview if it exists
    if list.preview_undo_text_edit ~= nil then
      require('blink.cmp.lib.text_edits').apply({ list.preview_undo_text_edit })
    end
    -- apply the new preview
    list.preview_undo_text_edit = require('blink.cmp.completion.accept.preview')(item)
  end)
end

---------- Accept ----------

function list.accept()
  local item = list.get_selected_item()
  if item == nil then return false end

  list.undo_preview()
  local accept = require('blink.cmp.completion.accept')
  accept(list.context, item, function() list.accept_emitter:emit({ item = item, context = list.context }) end)
  return true
end

return list
