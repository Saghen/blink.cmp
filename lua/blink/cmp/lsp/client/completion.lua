local async = require('blink.cmp.lib.async')

--- @class blink.cmp.lsp.cache.Entry
--- @field context blink.cmp.Context
--- @field response lsp.CompletionList

--- @class blink.cmp.lsp.cache
local cache = {
  --- @type table<number, blink.cmp.lsp.cache.Entry>
  entries = {},
}

function cache.get(context, client)
  local entry = cache.entries[client.id]
  if entry == nil then return end

  if context.id ~= entry.context.id then return end
  if entry.response.isIncomplete and entry.context.cursor[2] ~= context.cursor[2] then return end
  if not entry.response.isIncomplete and entry.context.cursor[2] > context.cursor[2] then return end

  return entry.response
end

--- @param context blink.cmp.Context
--- @param client vim.lsp.Client
--- @param response lsp.CompletionList
function cache.set(context, client, response)
  cache.entries[client.id] = {
    context = context,
    response = response,
  }
end

-----------------

--- @param context blink.cmp.Context
--- @param client vim.lsp.Client
--- @return blink.cmp.Task<lsp.CompletionList>
local function request(context, client)
  return async.task.new(function(resolve)
    local params = vim.lsp.util.make_position_params(0, client.offset_encoding)
    params.context = {
      triggerKind = context.trigger.kind == 'trigger_character'
          and vim.lsp.protocol.CompletionTriggerKind.TriggerCharacter
        or vim.lsp.protocol.CompletionTriggerKind.Invoked,
    }
    if context.trigger.kind == 'trigger_character' then params.context.triggerCharacter = context.trigger.character end

    local _, request_id = client:request('textDocument/completion', params, function(err, result)
      if err or result == nil then return resolve({ isIncomplete = false, items = {} }) end
      if result.isIncomplete ~= nil then return resolve(result) end
      resolve({ isIncomplete = false, items = result })
    end)
    return function()
      if request_id ~= nil then client:cancel_request(request_id) end
    end
  end)
end

local known_defaults = {
  commitCharacters = true,
  insertTextFormat = true,
  insertTextMode = true,
  data = true,
}

local function get_completions(context, client)
  local cache_entry = cache.get(context, client)
  if cache_entry ~= nil then return async.task.identity(cache_entry) end

  return request(context, client):map(function(res)
    local items = res.items or res
    local default_edit_range = res.itemDefaults and res.itemDefaults.editRange or text_edit.guess_edit_range()
    for _, item in ipairs(items) do
      item.blink_cmp = item.blink_cmp or {}
      item.blink_cmp.client_id = client.id
      item.blink_cmp.client_name = client.name

      -- score offset for deprecated items
      if item.deprecated or (item.tags and vim.tbl_contains(item.tags, 1)) then
        item.blink_cmp.score_offset = (item.blink_cmp.score_offset or 0) - 2
      end

      -- set defaults
      for key, value in pairs(res.itemDefaults or {}) do
        if known_defaults[key] then item[key] = item[key] or value end
      end
      if item.textEdit == nil then
        local new_text = item.textEditText or item.insertText or item.label
        if default_edit_range.replace ~= nil then
          item.textEdit = {
            replace = default_edit_range.replace,
            insert = default_edit_range.insert,
            newText = new_text,
          }
        else
          item.textEdit = {
            range = default_edit_range,
            newText = new_text,
          }
        end
      end
    end

    res.client_id = client.id
    return res
  end)
end

return get_completions
