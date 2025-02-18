local async = require('blink.cmp.lib.async')

-- How a completion was triggered
local InlineCompletionTriggerKind = {
  Invoked = 1,
  Automatic = 2,
}

local inline_completion = {}

--- @param context blink.cmp.Context
--- @param client vim.lsp.Client
--- @return blink.cmp.Task
function inline_completion.get_inlinecompletion_for_client(context, client)
  return async.task.new(function(resolve)
    local params = vim.lsp.util.make_position_params(0, client.offset_encoding)
    params.context = {
      triggerKind = context.trigger.kind == 'Invoked' and InlineCompletionTriggerKind.Invoked
        or InlineCompletionTriggerKind.Automatic,
    }

    params.formattingOptions = {
      tabSize = vim.fn.shiftwidth(),
      insertSpaces = vim.o.expandtab,
    }

    local _, request_id = client.request('textDocument/inlineCompletion', params, function(err, result)
      if err or result == nil then
        resolve({ is_incomplete_forward = true, is_incomplete_backward = true, items = {} })
        return
      end

      local items = result.items or result
      for _, item in ipairs(items) do
        item.client_id = client.id
        item.client_name = client.name
        item.documentation = item.insertText
        item.label = item.insertText
        item.kind = require('blink.cmp.types').CompletionItemKind.Snippet
        item.inline = true

        -- convert to traditional TextEdit
        item.textEdit = {
          newText = item.insertText,
          range = item.range,
        }
      end

      resolve({
        is_incomplete_forward = false,
        is_incomplete_backward = false,
        items = items,
      })
    end)

    -- cancellation function
    return function()
      if request_id ~= nil then client.cancel_request(request_id) end
    end
  end)
end

return inline_completion
