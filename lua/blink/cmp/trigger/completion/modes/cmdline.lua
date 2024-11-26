local cmdline_events = {}

function cmdline_events.new(trigger)
  local self = setmetatable({}, { __index = cmdline_events })
  self.trigger = trigger
  return self
end

function cmdline_events:activate()
  local trigger = self.trigger
  local config = require('blink.cmp.config').trigger.completion

  local previous_cmdline = ''

  vim.api.nvim_create_autocmd('CmdlineEnter', {
    callback = function() previous_cmdline = '' end,
  })

  vim.api.nvim_create_autocmd('CmdlineChanged', {
    callback = function()
      local cmdline = vim.fn.getcmdline()
      local cursor_col = vim.fn.getcmdpos()

      -- added a character
      if #cmdline > #previous_cmdline then
        local new_char = cmdline:sub(cursor_col - 1, cursor_col - 1)
        vim.print('Char: "' .. new_char .. '"')
        trigger.show({ mode = 'cmdline' })
      else
        -- removed a character
        trigger.show({ mode = 'cmdline' })
      end
      previous_cmdline = cmdline

      vim.print(
        'Command type: '
          .. vim.fn.getcmdtype()
          .. ' Command: '
          .. vim.fn.getcmdline()
          .. ' Position: '
          .. vim.fn.getcmdpos()
      )
    end,
  })

  vim.api.nvim_create_autocmd('CmdlineLeave', {
    callback = function() trigger.hide() end,
  })
end

return cmdline_events
