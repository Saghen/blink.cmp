local config = require('blink.cmp.config')
local completion = {}

function completion.setup()
  -- trigger controls when to show the window and the current context for caching
  local trigger = require('blink.cmp.completion.trigger')
  trigger.activate()

  -- sources fetch completion items and documentation
  local sources = require('blink.cmp.sources.lib')

  -- manages the completion list state:
  --   fuzzy matching items
  --   when to show/hide the windows
  --   selection
  --   accepting and previewing items
  local list = require('blink.cmp.completion.list')

  -- trigger -> sources: request completion items from the sources on show
  trigger.show_emitter:on(function(event) sources.request_completions(event.context) end)
  trigger.hide_emitter:on(function()
    sources.cancel_completions()
    list.hide()
  end)

  -- sources -> list
  sources.completions_emitter:on(function(event)
    -- schedule for later to avoid adding 0.5-4ms to insertion latency
    vim.schedule(function()
      -- since this was performed asynchronously, we check if the context has changed
      if trigger.context == nil or event.context.id ~= trigger.context.id then return end
      -- don't show the list if prefetching results
      if event.prefetch then return end
      list.show(event.context, event.items)
    end)
  end)

  --- list -> windows: ghost text and completion menu
  -- setup completion menu
  if config.completion.menu.enabled then
    list.show_emitter:on(
      function(event) require('blink.cmp.completion.windows.menu').open_with_items(event.context, event.items) end
    )
    list.hide_emitter:on(function() require('blink.cmp.completion.windows.menu').close() end)
    list.select_emitter:on(function(event)
      require('blink.cmp.completion.windows.menu').set_selected_item_idx(event.idx)
      require('blink.cmp.completion.windows.documentation').auto_show_item(event.item)
    end)
  end

  -- setup ghost text
  if config.completion.ghost_text.enabled then
    list.select_emitter:on(
      function(event) require('blink.cmp.completion.windows.ghost_text').show_preview(event.item) end
    )
    list.hide_emitter:on(function() require('blink.cmp.completion.windows.ghost_text').clear_preview() end)
  end

  -- run 'resolve' on the item ahead of time to avoid delays
  -- when accepting the item or showing documentation
  list.select_emitter:on(function(event)
    if event.item == nil then return end
    require('blink.cmp.completion.prefetch')(event.context, event.item)
  end)
end

return completion
