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

--- @param selected_item blink.cmp.CompletionItem
function ghost_text_preview.show_preview(selected_item)
  if selected_item == nil then return end

  local display_lines = vim.split(selected_item.label, '\n', { plain = true }) or {}
  display_lines[1] = display_lines[1]:gsub(get_text_before_cursor(), '')

  --- @type vim.api.keyset.set_extmark
  local extmark = {
    id = ghost_text_preview.extmark_id,
    virt_text_win_col = vim.fn.virtcol('.') - 1,
    virt_text = { { display_lines[1], 'BlinkCmpGhostText' } },
    hl_mode = 'combine',
  }

  if #display_lines > 1 then
    extmark.virt_lines = {}
    for i = 2, #display_lines do
      extmark.virt_lines[i - 1] = { { display_lines[i], 'BlinkCmpGhostText' } }
    end
  end

  local cursor_col = vim.fn.col('.')
  vim.api.nvim_buf_set_extmark(0, ghost_text_preview.ns_id, vim.fn.line('.') - 1, cursor_col - 1, extmark)
end

function ghost_text_preview.clear_preview()
  vim.api.nvim_buf_del_extmark(0, ghost_text_preview.ns_id, ghost_text_preview.extmark_id)
end

return ghost_text_preview
