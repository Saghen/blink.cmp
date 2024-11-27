local signature = {}

function signature.setup()
  local trigger = require('blink.cmp.signature.trigger')
  trigger.activate()
  local window = require('blink.cmp.signature.window')

  local sources = require('blink.cmp.sources.lib')

  trigger.show_emitter:on(function(event)
    local context = event.context
    sources.cancel_signature_help()
    sources.get_signature_help(context, function(signature_help)
      if signature_help ~= nil and trigger.context ~= nil and trigger.context.id == context.id then
        trigger.set_active_signature_help(signature_help)
        window.open_with_signature_help(context, signature_help)
      else
        trigger.hide()
      end
    end)
  end)
  trigger.hide_emitter:on(function() window.close() end)
end

return signature
