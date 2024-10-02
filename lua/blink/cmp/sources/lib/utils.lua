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

function utils.cache_get_completions_func(fn, module)
  local cached_function = {}
  cached_function.call = function(context)
    return fn(module, context):map(function(response)
      cached_function.last_context = context
      cached_function.last_response = response
      return response
    end)
  end
  return cached_function
end

return utils
