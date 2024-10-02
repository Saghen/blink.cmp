-- Handles hiding and showing the completion window. When a user types a trigger character
-- (provided by the sources) or anything matching the `context_regex`, we create a new `context`.
-- This can be used downstream to determine if we should make new requests to the sources or not.

--- @class blink.cmp.TriggerBounds
--- @field line string
--- @field line_number number
--- @field start_col number
--- @field end_col number
---
--- @class blink.cmp.Context
--- @field id number
--- @field bounds blink.cmp.TriggerBounds
--- @field bufnr number
--- @field treesitter_node table | nil
--- @field trigger { kind: number, character: string | nil }
---
--- @class blink.cmp.TriggerEventTargets
--- @field on_show fun(context: blink.cmp.Context)
--- @field on_hide fun()
---
--- @class blink.cmp.Trigger
--- @field context blink.cmp.Context | nil
--- @field current_context_id number
--- @field context_regex string
--- @field event_targets blink.cmp.TriggerEventTargets

local sources = require('blink.cmp.sources.lib')

--- @class blink.cmp.Trigger
local trigger = {
  current_context_id = -1,
  context = nil,
  context_regex = '[%w_\\-]',

  event_targets = {
    on_show = function() end,
    on_hide = function() end,
  },
}
local helpers = {}

function trigger.activate_autocmds()
  local last_char = ''
  vim.api.nvim_create_autocmd('InsertCharPre', {
    callback = function() last_char = vim.v.char end,
  })

  -- decide if we should show the completion window
  vim.api.nvim_create_autocmd('TextChangedI', {
    callback = function()
      -- character deleted so let cursormoved handle it
      if last_char == '' then return end

      -- ignore if in a special buffer
      if helpers.is_special_buffer() then
        trigger.hide()
      -- character forces a trigger according to the sources, create a fresh context
      elseif vim.tbl_contains(sources.get_trigger_characters(), last_char) then
        trigger.context = nil
        trigger.show({ trigger_character = last_char })
      -- character is part of the current context OR in an existing context
      elseif last_char:match(trigger.context_regex) ~= nil then
        trigger.show()
      -- nothing matches so hide
      else
        trigger.hide()
      end

      last_char = ''
    end,
  })

  -- check if we've moved outside of the context by diffing against the query boundary
  -- todo: should show if cursor is on trigger character
  vim.api.nvim_create_autocmd({ 'CursorMovedI', 'InsertEnter' }, {
    callback = function(ev)
      -- text changed so let textchanged handle it
      if last_char ~= '' then return end

      local is_within_bounds = trigger.within_query_bounds(vim.api.nvim_win_get_cursor(0))

      local cursor_col = vim.api.nvim_win_get_cursor(0)[2]
      local char_under_cursor = vim.api.nvim_get_current_line():sub(cursor_col, cursor_col)
      local is_on_trigger = vim.tbl_contains(sources.get_trigger_characters(), char_under_cursor)

      if is_within_bounds or (is_on_trigger and trigger.context ~= nil) then
        trigger.show()
      -- elseif is_on_trigger and ev.event == 'InsertEnter' then
      --   trigger.show({ trigger_character = char_under_cursor })
      else
        trigger.hide()
      end
    end,
  })

  -- definitely leaving the context
  vim.api.nvim_create_autocmd({ 'InsertLeave', 'BufLeave' }, { callback = trigger.hide })

  return trigger
end

--- @class blink.cmp.TriggerOptions
--- @field trigger_character string|nil
---
--- @param opts blink.cmp.TriggerOptions|nil
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
    bounds = helpers.get_context_bounds(trigger.context_regex),
    trigger = {
      kind = opts.trigger_character and vim.lsp.protocol.CompletionTriggerKind.TriggerCharacter
        or vim.lsp.protocol.CompletionTriggerKind.Invoked,
      character = opts.trigger_character,
    },
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

--- @param context blink.cmp.ShowContext | nil
--- @param cursor number[]
--- @return boolean
function trigger.within_query_bounds(cursor)
  if not trigger.context then return false end

  local row, col = cursor[1], cursor[2]
  local bounds = trigger.context.bounds
  return row == bounds.line_number and col >= bounds.start_col and col <= bounds.end_col
end

------ Helpers ------
function helpers.is_special_buffer()
  local bufnr = vim.api.nvim_get_current_buf()
  local buftype = vim.api.nvim_get_option_value('buftype', { buf = bufnr })
  return buftype ~= ''
end

-- Moves forward and backwards around the cursor looking for word boundaries
--- @param regex string
--- @return blink.cmp.TriggerBounds
function helpers.get_context_bounds(regex)
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

  return { line_number = cursor_line, start_col = start_col, end_col = end_col }
end

--- @return TSNode | nil
function helpers.get_treesitter_node_at_cursor()
  local ts = vim.treesitter
  local parser = ts.get_parser(0) -- Adjust language as needed
  if not parser then return end
  parser:parse()

  local cursor = vim.api.nvim_win_get_cursor(0)
  return ts.get_node({ bufnr = 0, pos = { cursor[1] - 1, math.max(0, cursor[2] - 1) } })
end

return trigger
