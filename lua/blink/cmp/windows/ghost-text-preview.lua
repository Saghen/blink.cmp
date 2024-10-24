local config = require('blink.cmp.config')

local ghost_text_preview = {
  extmark_id = 1,
  ns_id = config.highlight.ns,
}

local function get_text_before_cursor()
  local current_line = vim.api.nvim_get_current_line()
  local _, col = unpack(vim.api.nvim_win_get_cursor(0))

  return string.gsub(string.sub(current_line, 1, col), '^%s*', '')
end

--- @param str1 string
--- @param str2 string
--- @return string
local function get_overlapping_text_from(str1, str2)
  for i = 1, #str2 do
    local sub_str2 = string.sub(str2, i)
    if string.sub(str1, 1, #sub_str2) == sub_str2 then return sub_str2 end
  end
  return ''
end

--- @param selected_item? blink.cmp.CompletionItem
function ghost_text_preview.show_preview(selected_item)
  if selected_item == nil then return end

  local display_lines = vim.split(selected_item.label, '\n', { plain = true }) or {}
  display_lines[1] =
    string.gsub(display_lines[1], '^' .. get_overlapping_text_from(display_lines[1], get_text_before_cursor()), '')

  --- @type vim.api.keyset.set_extmark
  local extmark = {
    id = ghost_text_preview.extmark_id,
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

  local row, col = unpack(vim.api.nvim_win_get_cursor(0))
  vim.api.nvim_buf_set_extmark(0, ghost_text_preview.ns_id, row - 1, col, extmark)
end

function ghost_text_preview.clear_preview()
  vim.api.nvim_buf_del_extmark(0, ghost_text_preview.ns_id, ghost_text_preview.extmark_id)
end

return ghost_text_preview
