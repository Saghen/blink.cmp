--- @class (exact) blink.cmp.SnippetsConfig
--- @field preset 'default' | 'luasnip' | 'mini_snippets'
--- @field expand fun(snippet: string) Function to use when expanding LSP provided snippets
--- @field active fun(filter?: { direction?: number }): boolean Function to use when checking if a snippet is active
--- @field jump fun(direction: number) Function to use when jumping between tab stops in a snippet, where direction can be negative or positive

--- @param handlers table<'default' | 'luasnip' | 'mini_snippets', fun(...): any>
local function by_preset(handlers)
  return function(...)
    local preset = require('blink.cmp.config').snippets.preset
    return handlers[preset](...)
  end
end

local validate = require('blink.cmp.config.utils').validate
local snippets = {
  --- @type blink.cmp.SnippetsConfig
  default = {
    preset = 'default',
    -- NOTE: we wrap `vim.snippet` calls to reduce startup by 1-2ms
    expand = by_preset({
      default = function(snippet) vim.snippet.expand(snippet) end,
      luasnip = function(snippet) require('luasnip').lsp_expand(snippet) end,
      mini_snippets = function(snippet)
        if not _G.MiniSnippets then error('mini.snippets has not been setup') end
        local insert = MiniSnippets.config.expand.insert or MiniSnippets.default_insert
        insert(snippet)
      end,
    }),
    active = by_preset({
      default = function(filter) return vim.snippet.active(filter) end,
      luasnip = function(filter)
        if filter and filter.direction then return require('luasnip').jumpable(filter.direction) end
        return require('luasnip').in_snippet()
      end,
      mini_snippets = function()
        if not _G.MiniSnippets then error('mini.snippets has not been setup') end
        return MiniSnippets.session.get(false) ~= nil
      end,
    }),
    jump = by_preset({
      default = function(direction) vim.snippet.jump(direction) end,
      luasnip = function(direction) require('luasnip').jump(direction) end,
      mini_snippets = function(direction)
        if not _G.MiniSnippets then error('mini.snippets has not been setup') end
        MiniSnippets.session.jump(direction == -1 and 'prev' or 'next')
      end,
    }),
  },
}

function snippets.validate(config)
  validate('snippets', {
    preset = {
      config.preset,
      function(preset) return vim.tbl_contains({ 'default', 'luasnip', 'mini_snippets' }, preset) end,
      'one of: "default", "luasnip", "mini_snippets"',
    },
    expand = { config.expand, 'function' },
    active = { config.active, 'function' },
    jump = { config.jump, 'function' },
  }, config)
end

return snippets
