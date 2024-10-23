local utils = {}

--- Checks if a request should be made, based on the previous response/context
--- and the new context
---
--- @param new_context blink.cmp.Context
--- @param response blink.cmp.CompletionResponse
---
--- @return false | 'forward' | 'backward' | 'unknown'
function utils.should_run_request(new_context, response)
  local old_context = response.context
  -- get the text for the current and queued context
  local old_context_query = old_context.line:sub(old_context.bounds.start_col, old_context.cursor[2])
  local new_context_query = new_context.line:sub(new_context.bounds.start_col, new_context.cursor[2])

  -- check if the texts are overlapping
  local is_before = vim.startswith(old_context_query, new_context_query)
  local is_after = vim.startswith(new_context_query, old_context_query)

  if is_before and response.is_incomplete_backward then return 'forward' end
  if is_after and response.is_incomplete_forward then return 'backward' end
  if (is_after == is_before) and (response.is_incomplete_backward or response.is_incomplete_forward) then
    return 'unknown'
  end
  return false
end

--- @param responses blink.cmp.CompletionResponse[]
--- @return blink.cmp.CompletionResponse
function utils.concat_responses(responses)
  local is_cached = true
  local is_incomplete_forward = false
  local is_incomplete_backward = false
  local items = {}

  for _, response in ipairs(responses) do
    is_cached = is_cached and response.is_cached
    is_incomplete_forward = is_incomplete_forward or response.is_incomplete_forward
    is_incomplete_backward = is_incomplete_backward or response.is_incomplete_backward
    vim.list_extend(items, response.items)
  end

  return {
    is_cached = is_cached,
    is_incomplete_forward = is_incomplete_forward,
    is_incomplete_backward = is_incomplete_backward,
    items = items,
  }
end

--- @param item blink.cmp.CompletionItem
--- @return lsp.CompletionItem
function utils.blink_item_to_lsp_item(item)
  local lsp_item = vim.deepcopy(item)
  lsp_item.cursor_column = nil
  lsp_item.score_offset = nil
  lsp_item.client_id = nil
  lsp_item.source = nil
  lsp_item.source_name = nil
  return lsp_item
end

return utils
