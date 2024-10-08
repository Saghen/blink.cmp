-- Handles hiding and showing the completion window. When a user types a trigger character
-- (provided by the sources) or anything matching the `keyword_regex`, we create a new `context`.
-- This can be used downstream to determine if we should make new requests to the sources or not.

local config = require('blink.cmp.config').trigger.completion
local sources = require('blink.cmp.sources.lib')
local utils = require('blink.cmp.utils')

local trigger = {
  current_context_id = -1,
  --- @type blink.cmp.Context | nil
  context = nil,
  event_targets = {
    --- @type fun(context: blink.cmp.Context)
    on_show = function() end,
    --- @type fun()
    on_hide = function() end,
  },
}

function trigger.activate_autocmds()
  local last_char = ''
  vim.api.nvim_create_autocmd('InsertCharPre', {
    callback = function() last_char = vim.v.char end,
  })

  -- decide if we should show the completion window
  vim.api.nvim_create_autocmd('TextChangedI', {
    callback = function()
      -- no characters added so let cursormoved handle it
      if last_char == '' then return end

      -- ignore if in a special buffer
      if utils.is_special_buffer() then
        trigger.hide()
      -- character forces a trigger according to the sources, create a fresh context
      elseif vim.tbl_contains(sources.get_trigger_characters(), last_char) then
        trigger.context = nil
        trigger.show({ trigger_character = last_char })
      -- character is part of the current context OR in an existing context
      elseif last_char:match(config.keyword_regex) ~= nil then
        trigger.show()
      -- nothing matches so hide
      else
        trigger.hide()
      end

      last_char = ''
    end,
  })

  -- check if we've moved outside of the context by diffing against the query boundary
  vim.api.nvim_create_autocmd({ 'CursorMovedI', 'InsertEnter' }, {
    callback = function(ev)
      -- characters added so let textchanged handle it
      if last_char ~= '' then return end

      local is_within_bounds = trigger.within_query_bounds(vim.api.nvim_win_get_cursor(0))

      local cursor_col = vim.api.nvim_win_get_cursor(0)[2]
      local char_under_cursor = vim.api.nvim_get_current_line():sub(cursor_col, cursor_col)
      local is_on_trigger = vim.tbl_contains(sources.get_trigger_characters(), char_under_cursor)
        and not vim.tbl_contains(config.show_on_insert_blocked_trigger_characters, char_under_cursor)
      local is_on_context_char = char_under_cursor:match(config.keyword_regex) ~= nil

      if is_within_bounds then
        trigger.show()
      elseif
        -- check if we've gone 1 char behind the context and we're still on a context char
        (is_on_context_char and trigger.context ~= nil and cursor_col == trigger.context.bounds.start_col - 1)
        -- or if we've moved onto a trigger character
        or (is_on_trigger and trigger.context ~= nil)
      then
        trigger.context = nil
        trigger.show()
      elseif config.show_on_insert_on_trigger_character and is_on_trigger and ev.event == 'InsertEnter' then
        trigger.show({ trigger_character = char_under_cursor })
      else
        trigger.hide()
      end
    end,
  })

  -- definitely leaving the context
  vim.api.nvim_create_autocmd({ 'InsertLeave', 'BufLeave' }, { callback = trigger.hide })

  return trigger
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
    bounds = trigger.get_context_bounds(config.keyword_regex),
    trigger = {
      kind = opts.trigger_character and vim.lsp.protocol.CompletionTriggerKind.TriggerCharacter
        or vim.lsp.protocol.CompletionTriggerKind.Invoked,
      character = opts.trigger_character,
    },
  }

  trigger.event_targets.on_show(trigger.context)
end

--- @param callback fun(context: blink.cmp.Context)
function trigger.listen_on_show(callback) trigger.event_targets.on_show = callback end

function trigger.hide()
  if not trigger.context then return end

  trigger.context = nil
  trigger.event_targets.on_hide()
end

--- @param callback fun()
function trigger.listen_on_hide(callback) trigger.event_targets.on_hide = callback end

--- @param cursor number[]
--- @return boolean
function trigger.within_query_bounds(cursor)
  if not trigger.context then return false end

  local row, col = cursor[1], cursor[2]
  local bounds = trigger.context.bounds
  return row == bounds.line_number and col >= bounds.start_col and col <= bounds.end_col
end

--- Moves forward and backwards around the cursor looking for word boundaries
--- @param regex string
--- @return blink.cmp.ContextBounds
function trigger.get_context_bounds(regex)
  local cursor_line = vim.api.nvim_win_get_cursor(0)[1]
  local cursor_col = vim.api.nvim_win_get_cursor(0)[2]

  local line = vim.api.nvim_buf_get_lines(0, cursor_line - 1, cursor_line, false)[1]
  local start_col = cursor_col
  while start_col > 1 do
    local char = line:sub(start_col, start_col)
    if char:match(regex) == nil then
      start_col = start_col + 1
      break
    end
    start_col = start_col - 1
  end

  local end_col = cursor_col
  while end_col < #line do
    local char = line:sub(end_col + 1, end_col + 1)
    if char:match(regex) == nil then break end
    end_col = end_col + 1
  end

  -- hack: why do we have to math.min here?
  return { line_number = cursor_line, start_col = math.min(start_col, end_col), end_col = end_col }
end

return trigger
