--- Manages most of the state for the completion list such that downstream consumers can be mostly stateless
--- @class (exact) blink.cmp.CompletionList
--- @field config blink.cmp.CompletionListConfig
--- @field show_emitter blink.cmp.EventEmitter<blink.cmp.CompletionListShowEvent>
--- @field hide_emitter blink.cmp.EventEmitter<blink.cmp.CompletionListHideEvent>
--- @field select_emitter blink.cmp.EventEmitter<blink.cmp.CompletionListSelectEvent>
--- @field accept_emitter blink.cmp.EventEmitter<blink.cmp.CompletionListAcceptEvent>
---
--- @field context? blink.cmp.Context
--- @field items blink.cmp.CompletionItem[]
--- @field selected_item_idx? number
--- @field preview_undo? { text_edit: lsp.TextEdit, cursor_before?: integer[], cursor_after: integer[] }
---
--- @field show fun(context: blink.cmp.Context, items: table<string, blink.cmp.CompletionItem[]>)
--- @field fuzzy fun(context: blink.cmp.Context, items: table<string, blink.cmp.CompletionItem[]>): blink.cmp.CompletionItem[]
--- @field hide fun()
---
--- @field get_selected_item fun(): blink.cmp.CompletionItem?
--- @field get_selection_mode fun(context: blink.cmp.Context): { preselect: boolean, auto_insert: boolean }
--- @field get_item_idx_in_list fun(item?: blink.cmp.CompletionItem): number?
--- @field select fun(idx?: number, opts?: { auto_insert?: boolean, undo_preview?: boolean, is_explicit_selection?: boolean })
--- @field select_next fun(opts?: blink.cmp.CompletionListSelectOpts)
--- @field select_prev fun(opts?: blink.cmp.CompletionListSelectOpts)
---
--- @field undo_preview fun()
--- @field apply_preview fun(item: blink.cmp.CompletionItem)
--- @field accept fun(opts?: blink.cmp.CompletionListAcceptOpts): boolean Applies the currently selected item, returning true if it succeeded

--- @class blink.cmp.CompletionListSelectOpts
--- @field auto_insert? boolean When `true`, inserts the completion item automatically when selecting it

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

local context = require('blink.cmp.completion.trigger.context')

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
    list.select(previous_item_idx, { auto_insert = false, undo_preview = false })
  -- respect the context's initial selected item idx
  elseif context.initial_selected_item_idx ~= nil then
    list.select(context.initial_selected_item_idx, { undo_preview = false, is_explicit_selection = true })
  -- otherwise, use the default selection
  else
    list.select(
      list.get_selection_mode(context).preselect and 1 or nil,
      { auto_insert = false, undo_preview = false, is_explicit_selection = false }
    )
  end
end

function list.fuzzy(context, items_by_source)
  local fuzzy = require('blink.cmp.fuzzy')
  local filtered_items = fuzzy.fuzzy(
    context.get_line(),
    context.get_cursor()[2],
    items_by_source,
    require('blink.cmp.config').completion.keyword.range
  )

  -- apply the per source max_items
  filtered_items = require('blink.cmp.sources.lib').apply_max_items_for_completions(context, filtered_items)

  -- apply the global max_items
  return require('blink.cmp.lib.utils').slice(filtered_items, 1, list.config.max_items)
end

function list.hide() list.hide_emitter:emit({ context = list.context }) end

---------- Selection ----------

function list.get_selected_item() return list.items[list.selected_item_idx] end

function list.get_selection_mode(context)
  assert(context ~= nil, 'Context must be set before getting selection mode')

  local preselect = list.config.selection.preselect
  if type(preselect) == 'function' then preselect = preselect(context) end
  --- @cast preselect boolean

  local auto_insert = list.config.selection.auto_insert
  if type(auto_insert) == 'function' then auto_insert = auto_insert(context) end
  --- @cast auto_insert boolean

  return { preselect = preselect, auto_insert = auto_insert }
end

function list.get_item_idx_in_list(item)
  if item == nil then return end
  return require('blink.cmp.lib.utils').find_idx(list.items, function(i) return i.label == item.label end)
end

function list.select(idx, opts)
  opts = opts or {}
  local item = list.items[idx]

  local auto_insert = opts.auto_insert
  if auto_insert == nil then auto_insert = list.get_selection_mode(list.context).auto_insert end

  require('blink.cmp.completion.trigger').suppress_events_for_callback(function()
    if opts.undo_preview ~= false then list.undo_preview() end
    if auto_insert and item ~= nil then list.apply_preview(item) end
  end)

  --- @diagnostic disable-next-line: assign-type-mismatch
  list.is_explicitly_selected = opts.is_explicit_selection == nil and true or opts.is_explicit_selection
  list.selected_item_idx = idx
  list.select_emitter:emit({ idx = idx, item = item, items = list.items, context = list.context })
end

function list.select_next(opts)
  if #list.items == 0 or list.context == nil then return end

  -- haven't selected anything yet, select the first item
  if list.selected_item_idx == nil then return list.select(1, opts) end

  -- end of the list
  if list.selected_item_idx == #list.items then
    -- cycling around has been disabled, ignore
    if not list.config.cycle.from_bottom then return end

    -- preselect is not enabled, we go back to no selection
    if not list.get_selection_mode(list.context).preselect then return list.select(nil, opts) end

    -- otherwise, we cycle around
    return list.select(1, opts)
  end

  -- typical case, select the next item
  list.select(list.selected_item_idx + 1, opts)
end

function list.select_prev(opts)
  if #list.items == 0 or list.context == nil then return end

  -- haven't selected anything yet, select the last item
  if list.selected_item_idx == nil then return list.select(#list.items, opts) end

  -- start of the list
  if list.selected_item_idx == 1 then
    -- cycling around has been disabled, ignore
    if not list.config.cycle.from_top then return end

    -- auto_insert is enabled, we go back to no selection
    if list.get_selection_mode(list.context).auto_insert then return list.select(nil, opts) end

    -- otherwise, we cycle around
    return list.select(#list.items, opts)
  end

  -- typical case, select the previous item
  list.select(list.selected_item_idx - 1, opts)
end

---------- Preview ----------

function list.undo_preview()
  if list.preview_undo == nil then return end

  local text_edits_lib = require('blink.cmp.lib.text_edits')
  local text_edit = list.preview_undo.text_edit

  -- The text edit may be out of date due to the user typing more characters
  -- so we adjust the range to compensate
  local old_cursor_col = list.preview_undo.cursor_after[2]
  local new_cursor_col = context.get_cursor()[2]
  text_edit = text_edits_lib.compensate_for_cursor_movement(text_edit, old_cursor_col, new_cursor_col)

  require('blink.cmp.lib.text_edits').apply({ text_edit })
  if list.preview_undo.cursor_before ~= nil then
    require('blink.cmp.completion.trigger.context').set_cursor(list.preview_undo.cursor_before)
  end

  list.preview_undo = nil
end

function list.apply_preview(item)
  -- undo the previous preview if it exists
  list.undo_preview()

  -- apply the new preview
  local undo_text_edit, undo_cursor = require('blink.cmp.completion.accept.preview')(item)
  list.preview_undo = {
    text_edit = undo_text_edit,
    cursor_before = undo_cursor,
    cursor_after = context.get_cursor(),
  }
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
