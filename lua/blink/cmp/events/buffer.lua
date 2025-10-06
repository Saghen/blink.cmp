--- Exposes three events (cursor moved, char added, insert leave) for triggers to use.
--- Notably, when "char added" is fired, the "cursor moved" event will not be fired.
--- Unlike in regular neovim, ctrl + c and buffer switching will trigger "insert leave"

--- @class blink.cmp.BufferEventsListener
--- @field on_char_added fun(char: string)
--- @field on_cursor_moved fun()
--- @field on_insert_enter fun()
--- @field on_insert_leave fun()
--- @field on_complete_changed fun()

--- @class blink.cmp.BufferEvents
local buffer_events = {
  --- @type number?
  insert_char_pre_id = nil,
  --- @type number?
  char_added_id = nil,
  --- @type number?
  cursor_moved_id = nil,
}

--- @param opts blink.cmp.BufferEventsListener
function buffer_events.listen(opts)
  local self = setmetatable({}, { __index = buffer_events })

  vim.api.nvim_create_autocmd({ 'ModeChanged', 'BufLeave' }, {
    callback = function(ev)
      local mode = vim.api.nvim_get_mode().mode
      if mode:match('i') and ev.event == 'ModeChanged' then
        opts.on_insert_enter()
        self:subscribe(opts)
      elseif self:is_subscribed() then
        opts.on_insert_leave()
        self:unsubscribe()
      end
    end,
  })

  if opts.on_complete_changed then
    vim.api.nvim_create_autocmd('CompleteChanged', {
      callback = function() opts.on_complete_changed() end,
    })
  end

  return setmetatable({}, { __index = buffer_events })
end

--- @param opts blink.cmp.BufferEventsListener
function buffer_events:subscribe(opts)
  self:unsubscribe()

  local last_char = ''

  self.insert_char_pre_id = vim.api.nvim_create_autocmd('InsertCharPre', {
    -- FIXME: vim.v.char can be an escape code such as <95> in the case of <F2>. This breaks downstream
    -- since this isn't a valid utf-8 string. How can we identify and ignore these?
    callback = function() last_char = vim.v.char end,
  })

  self.char_added_id = vim.api.nvim_create_autocmd('TextChangedI', {
    callback = function()
      -- no character added so let cursormoved handle it
      if last_char == '' then return end

      opts.on_char_added(last_char)
      last_char = ''
    end,
  })

  self.cursor_moved_id = vim.api.nvim_create_autocmd({ 'CursorMoved', 'CursorMovedI' }, {
    callback = function()
      -- char added so textchanged will handle it
      if last_char ~= '' then return end
      opts.on_cursor_moved()
    end,
  })
end

function buffer_events:unsubscribe()
  if self.insert_char_pre_id ~= nil then
    vim.api.nvim_del_autocmd(self.insert_char_pre_id)
    self.insert_char_pre_id = nil
  end
  if self.char_added_id ~= nil then
    vim.api.nvim_del_autocmd(self.char_added_id)
    self.char_added_id = nil
  end
  if self.cursor_moved_id ~= nil then
    vim.api.nvim_del_autocmd(self.cursor_moved_id)
    self.cursor_moved_id = nil
  end
end

function buffer_events:is_subscribed()
  return self.insert_char_pre_id ~= nil or self.char_added_id ~= nil or self.cursor_moved_id ~= nil
end

return buffer_events
