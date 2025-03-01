--- LSPs may call "client commands" which must be registered inside of neovim
--- These are non-standard so we'll have to discover and implement them as we find them

local commands = {}

function commands.register()
  vim.lsp.commands['triggerParameterHints'] = function() require('blink.cmp').show_signature() end
  vim.lsp.commands['triggerSuggest'] = function()
    require('blink.cmp.completion.trigger').show({ trigger_kind = 'manual' })
  end
end

return commands
