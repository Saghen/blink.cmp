local sources = {
  registered = {
    lsp = require('blink.cmp.sources.lsp'),
    buffer = require('blink.cmp.sources.buffer'),
    snippets = require('blink.cmp.sources.snippets'),
  },
  in_flight = {
    lsp = false,
    buffer = false,
    snippets = false,
  },
  sources_items = {},
  current_context_id = -1,
  on_completions_callback = function(_) end,

  blocked_trigger_characters = {
    [' '] = true,
    ['\n'] = true,
    ['\t'] = true,
  },
}

function sources.get_trigger_characters()
  local trigger_characters = {}
  for _, source in pairs(sources.registered) do
    if source.get_trigger_characters ~= nil then
      local source_trigger_characters = source.get_trigger_characters()
      for _, char in ipairs(source_trigger_characters) do
        if not sources.blocked_trigger_characters[char] then table.insert(trigger_characters, char) end
      end
    end
  end
  return trigger_characters
end

function sources.listen_on_completions(callback) sources.on_completions_callback = callback end

function sources.completions(context)
  -- a new context means we should refetch everything
  local is_new_context = context.id ~= sources.current_context_id
  sources.current_context_id = context.id

  for source_name, source in pairs(sources.registered) do
    -- the source indicates we should refetch when this character is typed
    local trigger_characters = source.get_trigger_characters ~= nil and source.get_trigger_characters() or {}
    local trigger_character = context.trigger_character
      and vim.tbl_contains(trigger_characters, context.trigger_character)
    -- the source indicates the previous results were incomplete and should be refetched on the next trigger
    local previous_incomplete = sources.sources_items[source_name] ~= nil
      and sources.sources_items[source_name].isIncomplete
    -- check if we have no data and no calls are in flight
    local no_data = sources.sources_items[source_name] == nil and sources.in_flight[source_name] == false

    -- if none of these are true, we can use the existing cached results
    if is_new_context or trigger_character or previous_incomplete or no_data then
      if source.cancel_completions ~= nil then source.cancel_completions() end
      sources.in_flight[source_name] = true

      -- get the reason for the trigger
      local trigger_context = trigger_character
          and { kind = vim.lsp.protocol.CompletionTriggerKind.TriggerCharacter, character = context.trigger_character }
        or previous_incomplete and { kind = vim.lsp.protocol.CompletionTriggerKind.TriggerForIncompleteCompletions }
        or { kind = vim.lsp.protocol.CompletionTriggerKind.Invoked }

      -- fetch them completions
      -- fixme: what if we refetch due to incomplete items or a trigger_character? the context trigger id wouldnt change
      -- change so stale data would be returned if the source doesn't support cancellation
      local cursor_column = vim.api.nvim_win_get_cursor(0)[2]
      vim.schedule(function()
        source.completions({ trigger = trigger_context }, function(items)
          -- context id changing indicates our current data is out of date
          if sources.current_context_id ~= context.id then return end

          sources.in_flight[source_name] = false
          sources.add_source_completions(source_name, items, cursor_column)
          if not sources.some_in_flight() then sources.send_completions() end
        end)
      end)
    end
  end

  -- no completions will be in flight if none of them ran,
  -- so we send the completions
  if not sources.some_in_flight() then sources.send_completions() end
end

function sources.add_source_completions(source_name, source_items, cursor_column)
  for _, item in ipairs(source_items.items) do
    item.source = source_name
    item.cursor_column = cursor_column
  end

  sources.sources_items[source_name] = source_items
end

function sources.some_in_flight()
  for _, in_flight in pairs(sources.in_flight) do
    if in_flight == true then return true end
  end
  return false
end

function sources.send_completions()
  local sources_items = sources.sources_items
  -- apply source filters
  for _, source in pairs(sources.registered) do
    if source.filter_completions ~= nil then sources_items = source.filter_completions(sources_items) end
  end

  -- flatten the items
  local flattened_items = nil
  for _, response in pairs(sources.sources_items) do
    if flattened_items == nil then
      flattened_items = response.items
    else
      vim.list_extend(flattened_items, response.items)
    end
  end

  sources.on_completions_callback(flattened_items)
end

function sources.cancel_completions()
  for source_name, source in pairs(sources.registered) do
    sources.in_flight[source_name] = false
    if source.cancel_completions ~= nil then source.cancel_completions() end
  end
end

function sources.resolve(item, callback)
  local item_source = sources.registered[item.source]
  if item_source == nil or item_source.resolve == nil then return callback(item) end
  item_source.resolve(item, callback)
end

return sources
