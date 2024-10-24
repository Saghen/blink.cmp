local config = require('blink.cmp.config').accept.auto_brackets
local utils = require('blink.cmp.accept.brackets.utils')

local semantic = {}

--- Asynchronously use semantic tokens to determine if brackets should be added
--- @param filetype string
--- @param item blink.cmp.CompletionItem
--- @param callback fun()
function semantic.add_brackets_via_semantic_token(filetype, item, callback)
  if not utils.should_run_resolution(filetype, 'semantic_token') then return callback() end

  local text_edit = item.textEdit
  assert(text_edit ~= nil, 'Got nil text edit while adding brackets via semantic tokens')
  local client = vim.lsp.get_client_by_id(item.client_id)
  if client == nil then return callback() end

  local capabilities = client.server_capabilities.semanticTokensProvider
  if not capabilities or not capabilities.legend or (not capabilities.range and not capabilities.full) then
    return callback()
  end

  local token_types = client.server_capabilities.semanticTokensProvider.legend.tokenTypes
  local params = {
    textDocument = vim.lsp.util.make_text_document_params(),
    range = capabilities.range and {
      start = { line = text_edit.range.start.line, character = text_edit.range.start.character },
      ['end'] = { line = text_edit.range.start.line + 1, character = 0 },
    } or nil,
  }

  local cursor_before_call = vim.api.nvim_win_get_cursor(0)

  local start_time = vim.uv.hrtime()
  client.request(
    capabilities.range and 'textDocument/semanticTokens/range' or 'textDocument/semanticTokens/full',
    params,
    function(err, result)
      if err ~= nil or result == nil or #result.data == 0 then return callback() end

      -- cancel if it's been too long, or if the cursor moved
      local ms_since_call = (vim.uv.hrtime() - start_time) / 1000000
      local cursor_after_call = vim.api.nvim_win_get_cursor(0)
      if
        ms_since_call > config.semantic_token_resolution.timeout_ms
        or cursor_before_call[1] ~= cursor_after_call[1]
        or cursor_before_call[2] ~= cursor_after_call[2]
      then
        return callback()
      end

      for _, token in ipairs(semantic.process_semantic_token_data(result.data, token_types)) do
        if
          cursor_after_call[1] == token.line
          and cursor_after_call[2] >= token.start_col
          and cursor_after_call[2] <= token.end_col
          and (token.type == 'function' or token.type == 'method')
        then
          -- add the brackets
          local brackets_for_filetype = utils.get_for_filetype(filetype, item)
          local line = vim.api.nvim_get_current_line()
          local start_col = text_edit.range.start.character + #text_edit.newText
          local new_line = line:sub(1, start_col)
            .. brackets_for_filetype[1]
            .. brackets_for_filetype[2]
            .. line:sub(start_col + 1)
          vim.api.nvim_set_current_line(new_line)
          vim.api.nvim_win_set_cursor(0, { cursor_after_call[1], start_col + #brackets_for_filetype[1] })
          callback()
          return
        end
      end

      callback()
    end
  )
end

function semantic.process_semantic_token_data(data, token_types)
  local tokens = {}
  local idx = 0
  local token_line = 0
  local token_start_col = 0

  while (idx + 1) * 5 <= #data do
    local delta_token_line = data[idx * 5 + 1]
    local delta_token_start_col = data[idx * 5 + 2]
    local delta_token_length = data[idx * 5 + 3]
    local type = token_types[data[idx * 5 + 4] + 1]

    if delta_token_line > 0 then token_start_col = 0 end
    token_line = token_line + delta_token_line
    token_start_col = token_start_col + delta_token_start_col

    table.insert(tokens, {
      line = token_line + 1,
      start_col = token_start_col,
      end_col = token_start_col + delta_token_length,
      type = type,
    })

    token_start_col = token_start_col + delta_token_length
    idx = idx + 1
  end

  return tokens
end

return semantic.add_brackets_via_semantic_token
