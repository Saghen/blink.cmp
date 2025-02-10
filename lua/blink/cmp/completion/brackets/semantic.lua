local config = require('blink.cmp.config').completion.accept.auto_brackets
local utils = require('blink.cmp.completion.brackets.utils')

--- @class blink.cmp.SemanticRequest
--- @field start_time number
--- @field cursor integer[]
--- @field item blink.cmp.CompletionItem
--- @field filetype string
--- @field callback fun()

local semantic = {
  --- @type uv.uv_timer_t
  timer = assert(vim.uv.new_timer()),
  --- @type blink.cmp.SemanticRequest | nil
  request = nil,
}

vim.api.nvim_create_autocmd({ 'LspTokenUpdate' }, {
  callback = function(args)
    local token = args.data.token
    semantic.process_request({ token })
  end,
})

function semantic.finish_request()
  semantic.request.callback()
  semantic.request = nil
  semantic.timer:stop()
end

--- @param tokens STTokenRange[]
function semantic.process_request(tokens)
  if semantic.request == nil then return end

  local cursor = vim.api.nvim_win_get_cursor(0)
  -- cancel if the cursor moved
  if semantic.request.cursor[1] ~= cursor[1] or semantic.request.cursor[2] ~= cursor[2] then
    return semantic.finish_request()
  end

  for _, token in ipairs(tokens) do
    if
      (token.type == 'function' or token.type == 'method')
      and cursor[1] == token.line
      and cursor[2] >= token.start_col
      and cursor[2] < token.end_col
    then
      -- add the brackets
      local text_edit = assert(semantic.request.item.textEdit)
      local brackets_for_filetype = utils.get_for_filetype(semantic.request.filetype, semantic.request.item)
      local line = vim.api.nvim_get_current_line()
      local start_col = text_edit.range.start.character + #text_edit.newText
      local new_line = line:sub(1, start_col)
        .. brackets_for_filetype[1]
        .. brackets_for_filetype[2]
        .. line:sub(start_col + 1)
      vim.api.nvim_set_current_line(new_line)
      vim.api.nvim_win_set_cursor(0, { cursor[1], start_col + #brackets_for_filetype[1] })
      return semantic.finish_request()
    end
  end
end

--- Asynchronously use semantic tokens to determine if brackets should be added
--- @param ctx blink.cmp.Context
--- @param filetype string
--- @param item blink.cmp.CompletionItem
--- @param callback fun()
function semantic.add_brackets_via_semantic_token(ctx, filetype, item, callback)
  if not utils.should_run_resolution(ctx, filetype, 'semantic_token') then return callback() end

  assert(item.textEdit ~= nil, 'Got nil text edit while adding brackets via semantic tokens')
  local client = vim.lsp.get_client_by_id(item.client_id)
  if client == nil then return callback() end

  local capabilities = client.server_capabilities.semanticTokensProvider
  if not capabilities or not capabilities.legend or (not capabilities.range and not capabilities.full) then
    return callback()
  end

  semantic.request = {
    start_time = vim.uv.hrtime(),
    cursor = vim.api.nvim_win_get_cursor(0),
    filetype = filetype,
    item = item,
    callback = callback,
  }

  -- semantic tokens are only requested on InsertLeave and on_refresh, so manually force a refresh
  vim.lsp.semantic_tokens.force_refresh(ctx.bufnr)

  -- first check if a semantic token already exists at the current cursor position
  local tokens = vim.lsp.semantic_tokens.get_at_pos()
  if tokens ~= nil then semantic.process_request(tokens) end
  if semantic.request == nil then
    -- a matching token exists, and brackets were added
    return
  end

  -- listen for LspTokenUpdate events until timeout
  semantic.timer:start(config.semantic_token_resolution.timeout_ms, 0, semantic.finish_request)
end

return semantic.add_brackets_via_semantic_token
