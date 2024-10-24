local config = require('blink.cmp.config').accept.auto_brackets
local utils = require('blink.cmp.accept.brackets.utils')

--- @param filetype string
--- @param item blink.cmp.CompletionItem
--- @return 'added' | 'check_semantic_token' | 'skipped', lsp.TextEdit | lsp.InsertReplaceEdit, number
local function add_brackets(filetype, item)
  local text_edit = item.textEdit
  assert(text_edit ~= nil, 'Got nil text edit while adding brackets via kind')
  local brackets_for_filetype = utils.get_for_filetype(filetype, item)

  -- if there's already the correct brackets in front, skip but indicate the cursor should move in front of the bracket
  -- TODO: what if the brackets_for_filetype[1] == '' or ' ' (haskell/ocaml)?
  if utils.has_brackets_in_front(text_edit, brackets_for_filetype[1]) then
    return 'skipped', text_edit, #brackets_for_filetype[1]
  end

  -- if the item already contains the brackets, conservatively skip adding brackets
  -- todo: won't work for snippets when the brackets_for_filetype is { '{', '}' }
  -- I've never seen a language like that though
  if brackets_for_filetype[1] ~= ' ' and text_edit.newText:match('[\\' .. brackets_for_filetype[1] .. ']') ~= nil then
    return 'skipped', text_edit, 0
  end

  -- check if configuration incidates we should skip
  if not utils.should_run_resolution(filetype, 'kind') then return 'check_semantic_token', text_edit, 0 end
  -- not a function, skip
  local CompletionItemKind = require('blink.cmp.types').CompletionItemKind
  if item.kind ~= CompletionItemKind.Function and item.kind ~= CompletionItemKind.Method then
    return 'check_semantic_token', text_edit, 0
  end

  text_edit = vim.deepcopy(text_edit)
  -- For snippets, we add the cursor position between the brackets as the last placeholder
  if item.insertTextFormat == vim.lsp.protocol.InsertTextFormat.Snippet then
    local placeholders = utils.snippets_extract_placeholders(text_edit.newText)
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

return add_brackets
