--- @class blink.cmp.CmdlineEventsListener
--- @field on_char_added fun(char: string)
--- @field on_cursor_moved fun()
--- @field on_leave fun()

--- @class blink.cmp.CmdlineEvents
local cmdline_events = {}

--- @param opts blink.cmp.CmdlineEventsListener
function cmdline_events.listen(opts)
  -- Abbreviations and other automated features can cause rapid, repeated cursor movements
  -- (a "burst") that are not intentional user actions. To avoid reacting to these artificial
  -- movements in CursorMovedC, we detect bursts by measuring the time between moves.
  -- If two cursor moves occur within a short threshold (burst_threshold_ms), we treat them
  -- as part of a burst and ignore them.
  local last_move_time
  local burst_threshold_ms = 2
  local function is_burst_move()
    local current_time = vim.loop.hrtime() / 1e6
    local is_burst = last_move_time and (current_time - last_move_time) < burst_threshold_ms
    last_move_time = current_time
    return is_burst or false
  end

  -- TextChanged
  local pending_key
  local is_change_queued = false
  vim.on_key(function(raw_key, escaped_key)
    if vim.api.nvim_get_mode().mode ~= 'c' then return end

    -- ignore if it's a special key
    -- FIXME: odd behavior when escaped_key has multiple keycodes, e.g. by pressing <C-p> and then "t"
    local key = vim.fn.keytrans(escaped_key)
    if key:sub(1, 1) == '<' and key:sub(#key, #key) == '>' and raw_key ~= ' ' then return end
    if key == '' then return end

    last_move_time = vim.loop.hrtime() / 1e6
    pending_key = raw_key

    if not is_change_queued then
      is_change_queued = true
      vim.schedule(function()
        opts.on_char_added(pending_key)
        is_change_queued = false
        pending_key = nil
      end)
    end
  end)

  -- CursorMoved
  vim.api.nvim_create_autocmd('CursorMovedC', {
    callback = function()
      if not is_change_queued and not is_burst_move() then opts.on_cursor_moved() end
    end,
  })

  vim.api.nvim_create_autocmd('CmdlineLeave', {
    callback = function() opts.on_leave() end,
  })
end

return cmdline_events
