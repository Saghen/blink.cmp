local config = require('blink.cmp.config')
local autocomplete = require('blink.cmp.windows.autocomplete')

local ghost_text_config = config.windows.ghost_text

local ghost_text = {
  enabled = ghost_text_config and ghost_text_config.enabled,
  extmark_id = 1,
  ns_id = config.highlight.ns,
}

function ghost_text.setup()
  autocomplete.listen_on_select(function(item)
    if ghost_text.enabled ~= true then return end
    ghost_text.show_preview(item)
  end)
  autocomplete.listen_on_close(function() ghost_text.clear_preview() end)

  return ghost_text
end

--- @param textEdit lsp.TextEdit
local function get_still_untyped_text(textEdit)
  local type_text_length = textEdit.range['end'].character - textEdit.range.start.character
  local result = textEdit.newText:sub(type_text_length + 1)
  return result
end

--- @param selected_item? blink.cmp.CompletionItem
function ghost_text.show_preview(selected_item)
  if selected_item == nil then return end
  local text_edits_lib = require('blink.cmp.accept.text-edits')
  local text_edit = text_edits_lib.get_from_item(selected_item)

  if selected_item.insertTextFormat == vim.lsp.protocol.InsertTextFormat.Snippet then
    local expanded_snippet = require('blink.cmp.sources.snippets.utils').safe_parse(text_edit.newText)
    text_edit.newText = expanded_snippet and tostring(expanded_snippet) or text_edit.newText
  end

  local display_lines = vim.split(get_still_untyped_text(text_edit), '\n', { plain = true }) or {}

  --- @type vim.api.keyset.set_extmark
  local extmark = {
    id = ghost_text.extmark_id,
    virt_text_pos = 'inline',
    virt_text = { { display_lines[1], 'BlinkCmpGhostText' } },
    hl_mode = 'combine',
  }

  if #display_lines > 1 then
    extmark.virt_lines = {}
    for i = 2, #display_lines do
      extmark.virt_lines[i - 1] = { { display_lines[i], 'BlinkCmpGhostText' } }
    end
  end

  local cursor_pos = {
    text_edit.range.start.line,
    text_edit.range['end'].character,
  }
  vim.api.nvim_buf_set_extmark(0, ghost_text.ns_id, cursor_pos[1], cursor_pos[2], extmark)
end

function ghost_text.clear_preview() vim.api.nvim_buf_del_extmark(0, ghost_text.ns_id, ghost_text.extmark_id) end

return ghost_text
