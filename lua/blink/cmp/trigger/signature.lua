-- Handles hiding and showing the signature help window. When a user types a trigger character
-- (provided by the sources), we create a new `context`. This can be used downstream to determine
-- if we should make new requests to the sources or not. When a user types a re-trigger character,
-- we update the context's re-trigger counter.

-- TODO: ensure this always calls *after* the completion trigger to avoid increasing latency

local config = require('blink.cmp.config').trigger.signature_help
local sources = require('blink.cmp.sources.lib')
local utils = require('blink.cmp.utils')

local trigger = {
  current_context_id = -1,
  --- @type blink.cmp.SignatureHelpContext | nil
  context = nil,
  event_targets = {
    --- @type fun(context: blink.cmp.SignatureHelpContext)
    on_show = function() end,
    --- @type fun()
    on_hide = function() end,
  },
}

function trigger.activate_autocmds()
  local last_chars = {}
  vim.api.nvim_create_autocmd('InsertCharPre', {
    callback = function() table.insert(last_chars, vim.v.char) end,
  })

  -- decide if we should show the completion window
  vim.api.nvim_create_autocmd('TextChangedI', {
    callback = function()
      -- no characters added so let cursormoved handle it
      if #last_chars == 0 then return end

      local res = sources.get_signature_help_trigger_characters()
      local trigger_characters = res.trigger_characters
      local retrigger_characters = res.retrigger_characters

      for _, last_char in ipairs(last_chars) do
        -- ignore if in a special buffer
        if utils.is_blocked_buffer() then
          trigger.hide()
          break
        -- character forces a trigger according to the sources, refresh the existing context if it exists
        elseif vim.tbl_contains(trigger_characters, last_char) then
          trigger.show({ trigger_character = last_char })
          break
        -- character forces a re-trigger according to the sources, show if we have a context
        elseif vim.tbl_contains(retrigger_characters, last_char) and trigger.context ~= nil then
          trigger.show()
          break
        end
      end

      last_chars = {}
    end,
  })

  -- check if we've moved outside of the context by diffing against the query boundary
  vim.api.nvim_create_autocmd({ 'CursorMovedI', 'InsertEnter' }, {
    callback = function(ev)
      if utils.is_blocked_buffer() then return end

      -- characters added so let textchanged handle it
      if #last_chars ~= 0 then return end

      local cursor_col = vim.api.nvim_win_get_cursor(0)[2]
      local char_under_cursor = vim.api.nvim_get_current_line():sub(cursor_col, cursor_col)
      local is_on_trigger =
        vim.tbl_contains(sources.get_signature_help_trigger_characters().trigger_characters, char_under_cursor)

      if config.show_on_insert_on_trigger_character and is_on_trigger and ev.event == 'InsertEnter' then
        trigger.show({ trigger_character = char_under_cursor })
      elseif ev.event == 'CursorMovedI' and trigger.context ~= nil then
        trigger.show()
      end
    end,
  })

  -- definitely leaving the context
  vim.api.nvim_create_autocmd({ 'InsertLeave', 'BufLeave' }, { callback = trigger.hide })

  return trigger
end

function trigger.show_if_on_trigger_character()
  local cursor_col = vim.api.nvim_win_get_cursor(0)[2]
  local char_under_cursor = vim.api.nvim_get_current_line():sub(cursor_col, cursor_col)
  local is_on_trigger =
    vim.tbl_contains(sources.get_signature_help_trigger_characters().trigger_characters, char_under_cursor)
  if is_on_trigger then trigger.show({ trigger_character = char_under_cursor }) end
  return is_on_trigger
end

--- @param opts { trigger_character: string } | nil
function trigger.show(opts)
  opts = opts or {}

  -- update context
  local cursor = vim.api.nvim_win_get_cursor(0)
  if trigger.context == nil then trigger.current_context_id = trigger.current_context_id + 1 end
  trigger.context = {
    id = trigger.current_context_id,
    bufnr = vim.api.nvim_get_current_buf(),
    cursor = cursor,
    line = vim.api.nvim_buf_get_lines(0, cursor[1] - 1, cursor[1], false)[1],
    trigger = {
      kind = opts.trigger_character and vim.lsp.protocol.CompletionTriggerKind.TriggerCharacter
        or vim.lsp.protocol.CompletionTriggerKind.Invoked,
      character = opts.trigger_character,
    },
    is_retrigger = trigger.context ~= nil,
    active_signature_help = trigger.context and trigger.context.active_signature_help or nil,
  }

  trigger.event_targets.on_show(trigger.context)
end

function trigger.listen_on_show(callback) trigger.event_targets.on_show = callback end

function trigger.hide()
  if not trigger.context then return end

  trigger.context = nil
  trigger.event_targets.on_hide()
end

function trigger.listen_on_hide(callback) trigger.event_targets.on_hide = callback end

function trigger.set_active_signature_help(signature_help)
  if not trigger.context then return end
  trigger.context.active_signature_help = signature_help
end

return trigger
