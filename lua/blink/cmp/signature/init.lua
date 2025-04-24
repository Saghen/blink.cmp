local signature = {}

function signature.setup()
  local trigger = require('blink.cmp.signature.trigger')
  trigger.activate()

  local sources = require('blink.cmp.sources.lib')
  local window = require('blink.cmp.signature.window')

  trigger.show_emitter:on(function(event)
    local context = event.context
    sources.cancel_signature_help()

    if not context.by_show_on_insert then
      sources.get_signature_help(context):map(function(signature_helps)
        -- TODO: pick intelligently
        local signature_help = signature_helps[1]
        if signature_help ~= nil and trigger.context ~= nil and trigger.context.id == context.id then
          trigger.set_active_signature_help(signature_help)
          window.open_with_signature_help(context, signature_help)
        else
          trigger.hide()
        end
      end)
    else
      -- If triggered by show on insert, we also check the signature on the
      -- previous and following line to determine if we are in a multi-line
      -- callback, should abort if so.
      local context_current_line = context
      local context_previous_line = vim.deepcopy(context)
      context_previous_line.cursor[1] = context.cursor[1] - 1
      local context_following_line = vim.deepcopy(context)
      context_following_line.cursor[1] = context.cursor[1] + 1
      local label_previous_line, label_following_line, label_current_line

      sources.get_signature_help(context_previous_line):map(
        function(signature_helps) label_previous_line = signature_helps[1] and signature_helps[1].signatures[1].label end
      )
      sources.get_signature_help(context_following_line):map(
        function(signature_helps) label_following_line = signature_helps[1] and signature_helps[1].signatures[1].label end
      )

      sources.get_signature_help(context_current_line):map(function(signature_helps)
        local signature_help = signature_helps[1]
        label_current_line = signature_help and signature_help.signatures[1].label

        local is_multiline_callback = label_previous_line == label_current_line
          or label_following_line == label_current_line
        if
          signature_help ~= nil
          and trigger.context ~= nil
          and trigger.context.id == context.id
          and not is_multiline_callback
        then
          trigger.set_active_signature_help(signature_help)
          window.open_with_signature_help(context, signature_help)
        else
          trigger.hide()
        end
      end)
    end
  end)
  trigger.hide_emitter:on(function() window.close() end)
end

return signature
