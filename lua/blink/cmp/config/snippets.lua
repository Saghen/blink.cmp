--- @class (exact) blink.cmp.SnippetsConfig
--- @field expand fun(snippet: string)
--- @field active fun(filter?: { direction?: number }): boolean
--- @field jump fun(direction: number)

local validate = require('blink.cmp.config.utils').validate
local snippets = {
  --- @type blink.cmp.SnippetsConfig
  default = {
    -- NOTE: we wrap these in functions to reduce startup by 1-2ms
    -- when using lazy.nvim
    expand = function(snippet) vim.snippet.expand(snippet) end,
    active = function(filter) vim.snippet.active(filter) end,
    jump = function(direction) vim.snippet.jump(direction) end,
  },
}

function snippets.validate(config)
  validate('snippets', {
    expand = { config.expand, 'function' },
    active = { config.active, 'function' },
    jump = { config.jump, 'function' },
  })
end

return snippets
