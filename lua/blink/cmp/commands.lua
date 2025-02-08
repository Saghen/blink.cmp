local commands = {}

function commands.setup()
  vim.api.nvim_create_user_command('BlinkCmp', function(cmd)
    if cmd.fargs[1] == 'status' then
      vim.cmd('checkhealth blink.cmp')
    else
      vim.notify("[blink.cmp] invalid command '" .. cmd.args .. "'", vim.log.levels.ERROR)
    end
  end, { nargs = 1, complete = function() return { 'status' } end, desc = 'blink.cmp' })
end

return commands
