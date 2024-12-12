--- @class (exact) blink.cmp.CompletionConfig
--- @field keyword blink.cmp.CompletionKeywordConfig
--- @field trigger blink.cmp.CompletionTriggerConfig
--- @field list blink.cmp.CompletionListConfig
--- @field accept blink.cmp.CompletionAcceptConfig
--- @field menu blink.cmp.CompletionMenuConfig
--- @field documentation blink.cmp.CompletionDocumentationConfig
--- @field ghost_text blink.cmp.CompletionGhostTextConfig

local validate = require('blink.cmp.config.utils').validate
local completion = {
  default = {
    keyword = require('blink.cmp.config.completion.keyword').default,
    trigger = require('blink.cmp.config.completion.trigger').default,
    list = require('blink.cmp.config.completion.list').default,
    accept = require('blink.cmp.config.completion.accept').default,
    menu = require('blink.cmp.config.completion.menu').default,
    documentation = require('blink.cmp.config.completion.documentation').default,
    ghost_text = require('blink.cmp.config.completion.ghost_text').default,
  },
}

function completion.validate(config)
  validate('completion', {
    keyword = { config.keyword, 'table' },
    trigger = { config.trigger, 'table' },
    list = { config.list, 'table' },
    accept = { config.accept, 'table' },
    menu = { config.menu, 'table' },
    documentation = { config.documentation, 'table' },
    ghost_text = { config.ghost_text, 'table' },
  }, config)
  require('blink.cmp.config.completion.keyword').validate(config.keyword)
  require('blink.cmp.config.completion.trigger').validate(config.trigger)
  require('blink.cmp.config.completion.list').validate(config.list)
  require('blink.cmp.config.completion.accept').validate(config.accept)
  require('blink.cmp.config.completion.menu').validate(config.menu)
  require('blink.cmp.config.completion.documentation').validate(config.documentation)
  require('blink.cmp.config.completion.ghost_text').validate(config.ghost_text)
end

return completion
