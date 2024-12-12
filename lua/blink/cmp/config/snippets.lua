--- @class (exact) blink.cmp.SnippetsConfig
--- @field expand fun(snippet: string) Function to use when expanding LSP provided snippets
--- @field active fun(filter?: { direction?: number }): boolean Function to use when checking if a snippet is active
--- @field jump fun(direction: number) Function to use when jumping between tab stops in a snippet, where direction can be negative or positive

local validate = require('blink.cmp.config.utils').validate
local snippets = {
  --- @type blink.cmp.SnippetsConfig
  default = {
    -- NOTE: we wrap these in functions to reduce startup by 1-2ms
    -- when using lazy.nvim
    expand = function(snippet) vim.snippet.expand(snippet) end,
    active = function(filter) return vim.snippet.active(filter) end,
    jump = function(direction) vim.snippet.jump(direction) end,
  },
}

function snippets.validate(config)
  validate('snippets', {
    expand = { config.expand, 'function' },
    active = { config.active, 'function' },
    jump = { config.jump, 'function' },
  }, config)
end

return snippets
