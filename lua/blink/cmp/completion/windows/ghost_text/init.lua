local config = require('blink.cmp.config').completion.ghost_text
local highlight_ns = require('blink.cmp.config').appearance.highlight_ns

local text_edits_lib = require('blink.cmp.lib.text_edits')
local snippets_utils = require('blink.cmp.sources.snippets.utils')
local utils = require('blink.cmp.completion.windows.ghost_text.utils')
local menu = require('blink.cmp.completion.windows.menu')

--- @class blink.cmp.windows.GhostText
local ghost_text = {
  --- @type blink.cmp.CompletionItem?
  selected_item = nil,
  --- @type integer?
  extmark_id = nil,
  --- @type integer?
  extmark_buf = nil,
  --- @type integer
  ns = vim.api.nvim_create_namespace('blink_cmp_ghost_text'),
}

-- immediately re-draw the preview when the cursor moves/text changes
vim.api.nvim_create_autocmd({ 'CursorMovedI', 'TextChangedI' }, {
  callback = function() ghost_text.draw_preview() end,
})

-- immediately re-draw the preview when the menu opens/closes
menu.open_emitter:on(function()
  if ghost_text.is_open() and config.show_with_menu then return end
  ghost_text.draw_preview()
end)
menu.close_emitter:on(function()
  if ghost_text.is_open() and config.show_without_menu then return end
  ghost_text.draw_preview()
end)

function ghost_text.enabled()
  if type(config.enabled) == 'function' then return config.enabled() end
  return config.enabled
end

function ghost_text.is_open() return ghost_text.extmark_id ~= nil end

--- Shows the ghost text preview and sets up the state to automatically
--- redraw it when the cursor moves/text changes
--- @param items blink.cmp.CompletionItem[]
--- @param selection_idx? number
function ghost_text.show_preview(items, selection_idx)
  -- check if we're supposed to show
  if
    not config.show_with_selection and selection_idx ~= nil
    or not config.show_without_selection and selection_idx == nil
  then
    ghost_text.clear_preview()
    return
  end

  -- cmdline without noice not supported
  local ghost_text_buf = utils.get_buf()
  if ghost_text_buf == nil or not vim.api.nvim_buf_is_valid(ghost_text_buf) then return end

  -- nothing to show, clear the preview
  local selected_item = items[selection_idx or 1]
  if not selected_item then
    ghost_text.clear_preview()
    return
  end

  -- update state and redraw
  ghost_text.selected_item = selected_item

  vim.api.nvim_set_decoration_provider(ghost_text.ns, {
    on_win = function(_, _, buf) return (utils.is_cmdwin() or utils.is_noice()) and buf == ghost_text_buf end,
    on_line = function() ghost_text.draw_preview() end,
  })

  if utils.is_cmdline() then
    vim.api.nvim__redraw({ buf = ghost_text_buf, flush = true })
  else
    ghost_text.draw_preview()
  end
end

--- Redraws the ghost text preview if already shown,
--- and otherwise ignores the request
function ghost_text.draw_preview()
  -- check if we should be showing
  if
    not ghost_text.enabled()
    or (not config.show_with_menu and menu.win:is_open())
    or (not config.show_without_menu and not menu.win:is_open())
  then
    ghost_text.clear_preview()
    return
  end

  -- check if the state is valid
  if not ghost_text.selected_item then return end
  local buf = utils.get_buf()
  if buf == nil or not vim.api.nvim_buf_is_valid(buf) then return end

  -- get the text to draw
  local text_edit = text_edits_lib.get_from_item(ghost_text.selected_item)

  if ghost_text.selected_item.insertTextFormat == vim.lsp.protocol.InsertTextFormat.Snippet then
    local expanded_snippet = snippets_utils.safe_parse(text_edit.newText)
    text_edit.newText = expanded_snippet and snippets_utils.add_current_line_indentation(tostring(expanded_snippet))
      or text_edit.newText
  end

  local range = text_edit.range
  local typed_length = range['end'].character - range.start.character
  local extmark_col = range['end'].character

  -- For multiline edits, LSP's end.character may not always match the cursor column.
  -- (e.g. rust-analyzer with unmatched parens).
  -- Prefer the actual cursor position to avoid out-of-bounds errors.
  if range.start.line ~= range['end'].line then
    local cursor_col = vim.api.nvim_win_get_cursor(0)[2]
    typed_length = (cursor_col - 1) - range.start.character
    extmark_col = cursor_col
  end

  -- Clamp typed_length to valid bounds
  typed_length = math.max(0, math.min(typed_length, #text_edit.newText))

  local untyped_text = text_edit.newText:sub(typed_length + 1)
  local display_lines = vim.split(untyped_text, '\n', { plain = true }) or {}

  local virt_lines = {}
  for i = 2, #display_lines do
    virt_lines[i - 1] = { { display_lines[i], 'BlinkCmpGhostText' } }
  end

  ghost_text.extmark_id =
    vim.api.nvim_buf_set_extmark(buf, highlight_ns, range.start.line, extmark_col + utils.get_offset(), {
      id = ghost_text.extmark_id,
      virt_text_pos = 'inline',
      virt_text = { { display_lines[1], 'BlinkCmpGhostText' } },
      virt_lines = virt_lines,
      hl_mode = 'combine',
    })
  ghost_text.extmark_buf = buf

  utils.redraw_if_needed()
end

function ghost_text.clear_preview()
  ghost_text.selected_item = nil

  if ghost_text.extmark_id ~= nil then
    if ghost_text.extmark_buf ~= nil and vim.api.nvim_buf_is_valid(ghost_text.extmark_buf) then
      vim.api.nvim_buf_del_extmark(ghost_text.extmark_buf, highlight_ns, ghost_text.extmark_id)
    end

    ghost_text.extmark_id = nil
    utils.redraw_if_needed()
  end
end

return ghost_text
