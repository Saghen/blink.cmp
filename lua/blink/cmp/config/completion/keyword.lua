--- @class (exact) blink.cmp.CompletionKeywordConfig
--- @field range 'prefix' | 'full'
--- @field regex string
--- @field exclude_from_prefix_regex string

local validate = require('blink.cmp.config.utils').validate
local keyword = {
  --- @type blink.cmp.CompletionKeywordConfig
  default = {
    range = 'prefix',
    regex = '[%w_\\-]',
    exclude_from_prefix_regex = '[\\-]',
  },
}

function keyword.validate(config)
  validate('completion.keyword', {
    range = {
      config.range,
      function(range) return vim.tbl_contains({ 'prefix', 'full' }, range) end,
      'one of: prefix, full',
    },
    regex = { config.regex, 'string' },
    exclude_from_prefix_regex = { config.exclude_from_prefix_regex, 'string' },
  })
end

return keyword
