--- @class (exact) blink.cmp.CompletionKeywordConfig
--- 'prefix' will fuzzy match on the text before the cursor
--- 'full' will fuzzy match on the text before *and* after the cursor
--- example: 'foo_|_bar' will match 'foo_' for 'prefix' and 'foo__bar' for 'full'
--- @field range blink.cmp.CompletionKeywordRange
--- @field regex string Regex used to get the text when fuzzy matching
--- @field exclude_from_prefix_regex string After matching with regex, any characters matching this regex at the prefix will be excluded
---
--- @alias blink.cmp.CompletionKeywordRange
--- | 'prefix' Fuzzy match on the text before the cursor (example: 'foo_|bar' will match 'foo_')
--- | 'full' Fuzzy match on the text before *and* after the cursor (example: 'foo_|_bar' will match 'foo__bar')

local validate = require('blink.cmp.config.utils').validate
local keyword = {
  --- @type blink.cmp.CompletionKeywordConfig
  default = {
    range = 'prefix',
    regex = '[-_]\\|\\k',
    exclude_from_prefix_regex = '-',
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
  }, config)
end

return keyword
