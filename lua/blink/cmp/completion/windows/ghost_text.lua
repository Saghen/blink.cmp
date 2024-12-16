local config = require('blink.cmp.config').completion.ghost_text
local highlight_ns = require('blink.cmp.config').appearance.highlight_ns
local text_edits_lib = require('blink.cmp.lib.text_edits')
local snippets_utils = require('blink.cmp.sources.snippets.utils')

--- @class blink.cmp.windows.GhostText
--- @field win integer?
--- @field selected_item blink.cmp.CompletionItem?
--- @field extmark_id integer?
---
--- @field is_open fun(): boolean
--- @field show_preview fun(item: blink.cmp.CompletionItem)
--- @field clear_preview fun()
--- @field draw_preview fun(bufnr: number)

--- @type blink.cmp.windows.GhostText
--- @diagnostic disable-next-line: missing-fields
local ghost_text = {
  win = nil,
  selected_item = nil,
  extmark_id = nil,
}

--- @param textEdit lsp.TextEdit
local function get_still_untyped_text(textEdit)
  local type_text_length = textEdit.range['end'].character - textEdit.range.start.character
  return textEdit.newText:sub(type_text_length + 1)
end

-- immediately re-draw the preview when the cursor moves/text changes
vim.api.nvim_create_autocmd({ 'CursorMovedI', 'TextChangedI' }, {
  callback = function()
    if config.enabled and ghost_text.win then ghost_text.draw_preview(vim.api.nvim_win_get_buf(ghost_text.win)) end
  end,
})

function ghost_text.is_open() return ghost_text.extmark_id ~= nil end

--- @param selected_item? blink.cmp.CompletionItem
function ghost_text.show_preview(selected_item)
  -- nothing to show, clear the preview
  if not selected_item then
    ghost_text.clear_preview()
    return
  end

  -- doesn't work in command mode
  -- TODO: integrate with noice.nvim?
  if vim.api.nvim_get_mode().mode == 'c' then return end

  -- update state and redraw
  local changed = ghost_text.selected_item ~= selected_item
  ghost_text.selected_item = selected_item
  ghost_text.win = vim.api.nvim_get_current_win()
  if changed then ghost_text.draw_preview(vim.api.nvim_win_get_buf(ghost_text.win)) end
end

function ghost_text.clear_preview()
  ghost_text.selected_item = nil
  ghost_text.win = nil
  if ghost_text.extmark_id ~= nil then
    vim.api.nvim_buf_del_extmark(0, highlight_ns, ghost_text.extmark_id)
    ghost_text.extmark_id = nil
  end
end

function ghost_text.draw_preview(bufnr)
  if not ghost_text.selected_item then return end

  local text_edit = text_edits_lib.get_from_item(ghost_text.selected_item)

  if ghost_text.selected_item.insertTextFormat == vim.lsp.protocol.InsertTextFormat.Snippet then
    local expanded_snippet = snippets_utils.safe_parse(text_edit.newText)
    text_edit.newText = expanded_snippet and tostring(expanded_snippet) or text_edit.newText
  end

  local display_lines = vim.split(get_still_untyped_text(text_edit), '\n', { plain = true }) or {}

  local virt_lines = {}
  if #display_lines > 1 then
    for i = 2, #display_lines do
      virt_lines[i - 1] = { { display_lines[i], 'BlinkCmpGhostText' } }
    end
  end

  local cursor_pos = {
    text_edit.range.start.line,
    text_edit.range['end'].character,
  }

  ghost_text.extmark_id = vim.api.nvim_buf_set_extmark(bufnr, highlight_ns, cursor_pos[1], cursor_pos[2], {
    id = ghost_text.extmark_id,
    virt_text_pos = 'inline',
    virt_text = { { display_lines[1], 'BlinkCmpGhostText' } },
    virt_lines = virt_lines,
    hl_mode = 'combine',
  })
end

return ghost_text
