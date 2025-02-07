local async = require('blink.cmp.lib.async')
local known_defaults = {
  'commitCharacters',
  'insertTextFormat',
  'insertTextMode',
  'data',
}
local CompletionTriggerKind = vim.lsp.protocol.CompletionTriggerKind

local completion = {}

--- @param context blink.cmp.Context
--- @param client vim.lsp.Client
--- @return blink.cmp.Task
function completion.get_completion_for_client(context, client)
  return async.task.new(function(resolve)
    local params = vim.lsp.util.make_position_params(0, client.offset_encoding)
    params.context = {
      triggerKind = context.trigger.kind == 'trigger_character' and CompletionTriggerKind.TriggerCharacter
        or CompletionTriggerKind.Invoked,
    }
    if context.trigger.kind == 'trigger_character' then params.context.triggerCharacter = context.trigger.character end

    local _, request_id = client.request('textDocument/completion', params, function(err, result)
      if err or result == nil then
        resolve({ is_incomplete_forward = true, is_incomplete_backward = true, items = {} })
        return
      end

      local items = result.items or result
      local default_edit_range = result.itemDefaults and result.itemDefaults.editRange
      for _, item in ipairs(items) do
        item.client_id = client.id
        item.client_name = client.name

        -- score offset for deprecated items
        -- todo: make configurable
        if item.deprecated or (item.tags and vim.tbl_contains(item.tags, 1)) then item.score_offset = -2 end

        -- set defaults
        for key, value in pairs(result.itemDefaults or {}) do
          if vim.tbl_contains(known_defaults, key) then item[key] = item[key] or value end
        end
        if default_edit_range and item.textEdit == nil then
          local new_text = item.textEditText or item.insertText or item.label
          if default_edit_range.replace ~= nil then
            item.textEdit = {
              replace = default_edit_range.replace,
              insert = default_edit_range.insert,
              newText = new_text,
            }
          else
            item.textEdit = {
              range = result.itemDefaults.editRange,
              newText = new_text,
            }
          end
        end
      end

      resolve({
        is_incomplete_forward = result.isIncomplete or false,
        is_incomplete_backward = true,
        items = items,
      })
    end)

    -- cancellation function
    return function()
      if request_id ~= nil then client.cancel_request(request_id) end
    end
  end)
end

return completion
