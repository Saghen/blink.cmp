local commands = {}

function commands.status()
  local sources = require('blink.cmp.sources.lib')
  local all_providers = sources.get_all_providers()
  local enabled_provider_ids = sources.get_enabled_provider_ids('default')

  --- @type string[]
  local not_enabled_provider_ids = {}
  for provider_id, _ in pairs(all_providers) do
    if not vim.list_contains(enabled_provider_ids, provider_id) then
      table.insert(not_enabled_provider_ids, provider_id)
    end
  end

  if #enabled_provider_ids > 0 then
    vim.api.nvim_echo({ { '\n', 'Normal' } }, false, {})
    vim.api.nvim_echo({ { '# enabled sources providers\n', 'Special' } }, false, {})

    for _, provider_id in ipairs(enabled_provider_ids) do
      vim.api.nvim_echo({ { ('- %s\n'):format(provider_id), 'Normal' } }, false, {})
    end
  end

  if #not_enabled_provider_ids > 0 then
    vim.api.nvim_echo({ { '\n', 'Normal' } }, false, {})
    vim.api.nvim_echo({ { '# not enabled sources providers\n', 'Comment' } }, false, {})

    for _, provider_id in pairs(not_enabled_provider_ids) do
      vim.api.nvim_echo({ { ('- %s\n'):format(provider_id), 'Normal' } }, false, {})
    end
  end
end

function commands.setup()
  vim.api.nvim_create_user_command('BlinkCmp', function(cmd)
    if cmd.fargs[1] == 'status' then
      commands.status()
    else
      vim.notify("[blink.cmp] invalid command '" .. cmd.args .. "'", vim.log.levels.ERROR)
    end
  end, { nargs = 1, complete = function() return { 'status' } end, desc = 'blink.cmp' })
end

return commands
