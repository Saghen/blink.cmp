--- @class (exact) blink.cmp.ConfigStrict
--- @field blocked_filetypes string[]
--- @field keymap blink.cmp.KeymapConfig
--- @field completion blink.cmp.CompletionConfig
--- @field fuzzy blink.cmp.FuzzyConfig
--- @field sources blink.cmp.SourceConfig
--- @field signature blink.cmp.SignatureConfig
--- @field snippets blink.cmp.SnippetsConfig
--- @field appearance blink.cmp.AppearanceConfig

--- @class (exact) blink.cmp.Config : blink.cmp.ConfigStrict
--- HACK: for some reason lua-language-server treats this as Partial<ConfigStrict>
--- but this seems to be a bug. See https://github.com/LuaLS/lua-language-server/issues/2561
--- Much easier than copying every class and marking everything as optional for now :)

local validate = require('blink.cmp.config.utils').validate
--- @type blink.cmp.ConfigStrict
local config = {
  blocked_filetypes = {},
  keymap = require('blink.cmp.config.keymap').default,
  completion = require('blink.cmp.config.completion').default,
  fuzzy = require('blink.cmp.config.fuzzy').default,
  sources = require('blink.cmp.config.sources').default,
  signature = require('blink.cmp.config.signature').default,
  snippets = require('blink.cmp.config.snippets').default,
  appearance = require('blink.cmp.config.appearance').default,
}

--- @type blink.cmp.Config
local M = {}

--- @param self blink.cmp.ConfigStrict
function M.validate(self)
  validate('config', {
    blocked_filetypes = { self.blocked_filetypes, 'table' },
    keymap = { self.keymap, 'table' },
    completion = { self.completion, 'table' },
    sources = { self.sources, 'table' },
    signature = { self.signature, 'table' },
    snippets = { self.snippets, 'table' },
    appearance = { self.appearance, 'table' },
  })
  require('blink.cmp.config.completion').validate(self.completion)
  require('blink.cmp.config.sources').validate(self.sources)
  require('blink.cmp.config.signature').validate(self.signature)
  require('blink.cmp.config.snippets').validate(self.snippets)
  require('blink.cmp.config.appearance').validate(self.appearance)
end

--- @param user_config blink.cmp.Config
function M.merge_with(user_config)
  config = vim.tbl_deep_extend('force', config, user_config)
  M.validate(config)
end

return setmetatable(M, { __index = function(_, k) return config[k] end })
