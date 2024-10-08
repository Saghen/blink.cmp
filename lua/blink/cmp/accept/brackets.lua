-- todo: support for edge cases like <>() for typescript when checking
-- if brackets are already added

local config = require('blink.cmp.config').accept.auto_brackets
local brackets = {
  -- stylua: ignore
  blocked_filetypes = {
    'rust', 'sql', 'ruby', 'perl', 'lisp', 'scheme', 'clojure',
    'prolog', 'vb', 'elixir', 'smalltalk', 'applescript'
  },
  per_filetype = {
    -- languages with a space
    haskell = { ' ', '' },
    fsharp = { ' ', '' },
    ocaml = { ' ', '' },
    erlang = { ' ', '' },
    tcl = { ' ', '' },
    nix = { ' ', '' },
    helm = { ' ', '' },

    shell = { ' ', '' },
    sh = { ' ', '' },
    bash = { ' ', '' },
    fish = { ' ', '' },
    zsh = { ' ', '' },
    powershell = { ' ', '' },

    make = { ' ', '' },

    -- languages with square brackets
    wl = { '[', ']' },
    wolfram = { '[', ']' },
    mma = { '[', ']' },
    mathematica = { '[', ']' },
  },
}

--- @param filetype string
--- @param item blink.cmp.CompletionItem
--- @return 'added' | 'check_semantic_token' | 'skipped', lsp.TextEdit | lsp.InsertReplaceEdit, number
function brackets.add_brackets(filetype, item)
  local text_edit = item.textEdit
  assert(text_edit ~= nil, 'Got nil text edit while adding brackets via kind')
  local brackets_for_filetype = brackets.get_for_filetype(filetype, item)

  -- if there's already the correct brackets in front, skip but indicate the cursor should move in front of the bracket
  -- TODO: what if the brackets_for_filetype[1] == '' or ' ' (haskell/ocaml)?
  if brackets.has_brackets_in_front(text_edit, brackets_for_filetype[1]) then
    return 'skipped', text_edit, #brackets_for_filetype[1]
  end
  -- check if configuration incidates we should skip
  if not brackets.should_run_resolution(filetype, 'kind') then return 'check_semantic_token', text_edit, 0 end
  -- not a function, skip
  if
    item.kind ~= vim.lsp.protocol.CompletionItemKind.Function
    and item.kind ~= vim.lsp.protocol.CompletionItemKind.Method
  then
    return 'check_semantic_token', text_edit, 0
  end

  -- if the item already contains the brackets, conservatively skip adding brackets
  -- todo: won't work for snippets when the brackets_for_filetype is { '{', '}' }
  -- I've never seen a language like that though
  if brackets_for_filetype[1] ~= ' ' and text_edit.newText:match('[\\' .. brackets_for_filetype[1] .. ']') ~= nil then
    return 'skipped', text_edit, 0
  end

  text_edit = vim.deepcopy(text_edit)
  -- For snippets, we add the cursor position between the brackets as the last placeholder
  if item.insertTextFormat == vim.lsp.protocol.InsertTextFormat.Snippet then
    local placeholders = brackets.snippets_extract_placeholders(text_edit.newText)
    local last_placeholder_index = math.max(0, unpack(placeholders))
    text_edit.newText = text_edit.newText
      .. brackets_for_filetype[1]
      .. '$'
      .. tostring(last_placeholder_index + 1)
      .. brackets_for_filetype[2]
  -- Otherwise, we add as usual
  else
    text_edit.newText = text_edit.newText .. brackets_for_filetype[1] .. brackets_for_filetype[2]
  end
  return 'added', text_edit, -#brackets_for_filetype[2]
end

--- @param snippet string
function brackets.snippets_extract_placeholders(snippet)
  local placeholders = {}
  local pattern = [=[(\$\{(\d+)(:([^}\\]|\\.)*?)?\})]=]

  for _, number, _, _ in snippet:gmatch(pattern) do
    table.insert(placeholders, tonumber(number))
  end

  return placeholders
end

--- Asynchronously use semantic tokens to determine if brackets should be added
--- @param filetype string
--- @param item blink.cmp.CompletionItem
--- @param callback fun()
function brackets.add_brackets_via_semantic_token(filetype, item, callback)
  if not brackets.should_run_resolution(filetype, 'semantic_token') then return callback() end

  local text_edit = item.textEdit
  assert(text_edit ~= nil, 'Got nil text edit while adding brackets via semantic tokens')
  local client = vim.lsp.get_client_by_id(item.client_id)
  if client == nil then return callback() end

  local start_time = vim.uv.hrtime()
  if not (client.server_capabilities.semanticTokensProvider and client.server_capabilities.semanticTokensProvider.legend) then
    return callback()
  end
  local numToTokenType = client.server_capabilities.semanticTokensProvider.legend.tokenTypes
  local params = {
    textDocument = vim.lsp.util.make_text_document_params(),
    range = {
      start = { line = text_edit.range.start.line, character = text_edit.range.start.character },
      ['end'] = { line = text_edit.range.start.line + 1, character = 0 },
    },
  }

  local cursor_before_call = vim.api.nvim_win_get_cursor(0)

  client.request('textDocument/semanticTokens/range', params, function(err, result)
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

    -- cancel if the token isn't a function or method
    local type = numToTokenType[result.data[4] + 1]
    if type ~= 'function' and type ~= 'method' then return callback() end

    -- add the brackets
    local brackets_for_filetype = brackets.get_for_filetype(filetype, item)
    local line = vim.api.nvim_get_current_line()
    local start_col = text_edit.range.start.character + #text_edit.newText
    local new_line = line:sub(1, start_col)
      .. brackets_for_filetype[1]
      .. brackets_for_filetype[2]
      .. line:sub(start_col + 1)
    vim.api.nvim_set_current_line(new_line)
    vim.api.nvim_win_set_cursor(0, { cursor_after_call[1], start_col + #brackets_for_filetype[1] })

    callback()
  end)
end

--- @param filetype string
--- @param item blink.cmp.CompletionItem
--- @return string[]
function brackets.get_for_filetype(filetype, item)
  local default = config.default_brackets
  local per_filetype = config.override_brackets_for_filetypes[filetype] or brackets.per_filetype[filetype]

  if type(per_filetype) == 'function' then return per_filetype(item) or default end
  return per_filetype or default
end

--- @param filetype string
--- @param resolution_method 'kind' | 'semantic_token'
--- @return boolean
function brackets.should_run_resolution(filetype, resolution_method)
  -- resolution method specific
  if not config[resolution_method .. '_resolution'].enabled then return false end
  local resolution_blocked_filetypes = config[resolution_method .. '_resolution'].blocked_filetypes
  if vim.tbl_contains(resolution_blocked_filetypes, filetype) then return false end

  -- global
  if not config.enabled then return false end
  if vim.tbl_contains(config.force_allow_filetypes, filetype) then return true end
  return not vim.tbl_contains(config.blocked_filetypes, filetype)
end

--- @param text_edit lsp.TextEdit | lsp.InsertReplaceEdit
--- @param bracket string
--- @return boolean
function brackets.has_brackets_in_front(text_edit, bracket)
  local line = vim.api.nvim_get_current_line()
  local col = text_edit.range['end'].character + 1
  return line:sub(col, col) == bracket
end

return brackets
