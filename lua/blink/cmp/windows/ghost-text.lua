local config = require('blink.cmp.config')
local autocomplete = require('blink.cmp.windows.autocomplete')
local text_edits_lib = require('blink.cmp.accept.text-edits')
local snippets_utils = require('blink.cmp.sources.snippets.utils')

local ghost_text_config = config.windows.ghost_text

---@class blink.cmp.windows.ghost_text
---@field enabled boolean
---@field ns_id integer
---@field extmark_id integer?
---@field win integer?
---@field selected_item blink.cmp.CompletionItem?
local ghost_text = {
  enabled = ghost_text_config and ghost_text_config.enabled or false,
  ns_id = vim.api.nvim_create_namespace('blink_cmp.ghost_text'),
  extmark_id = nil,
  win = nil,
  selected_item = nil,
}

--- @param textEdit lsp.TextEdit
local function get_still_untyped_text(textEdit)
  local type_text_length = textEdit.range['end'].character - textEdit.range.start.character
  local result = textEdit.newText:sub(type_text_length + 1)
  return result
end

function ghost_text.setup()
  local self = setmetatable({}, { __index = ghost_text })

  vim.api.nvim_set_decoration_provider(self.ns_id, {
    on_win = function(_, win)
      if self.extmark_id then
        vim.api.nvim_buf_del_extmark(vim.api.nvim_win_get_buf(self.win), self.ns_id, self.extmark_id)
        self.extmark_id = nil
      end

      if win ~= self.win then return false end

      if (not self.enabled) or not self.selected_item then return end

      local text_edit = text_edits_lib.get_from_item(self.selected_item)

      if self.selected_item.insertTextFormat == vim.lsp.protocol.InsertTextFormat.Snippet then
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

      self.extmark_id = vim.api.nvim_buf_set_extmark(
        vim.api.nvim_win_get_buf(self.win),
        ghost_text.ns_id,
        cursor_pos[1],
        cursor_pos[2],
        {
          virt_text_pos = 'inline',
          virt_text = { { display_lines[1], 'BlinkCmpGhostText' } },
          virt_lines = virt_lines,
          hl_mode = 'combine',
          ephemeral = false,
        }
      )
    end,
  })

  autocomplete.listen_on_select(function(item)
    if ghost_text.enabled ~= true then return end
    ghost_text:show_preview(item)
  end)
  autocomplete.listen_on_close(function() ghost_text:clear_preview() end)

  return ghost_text
end

--- @param selected_item? blink.cmp.CompletionItem
function ghost_text:show_preview(selected_item)
  if not selected_item then
    self.selected_item = nil
    return
  end
  local changed = self.selected_item ~= selected_item
  self.selected_item = selected_item
  self.win = vim.api.nvim_get_current_win()
  if changed then vim.cmd.redraw({ bang = true }) end
end

function ghost_text:clear_preview()
  if self.win and self.selected_item then
    self.selected_item = nil
    vim.cmd.redraw({ bang = true })
  end
end

return ghost_text
