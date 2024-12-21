--- @class (exact) blink.cmp.ConfigStrict
--- @field enabled fun(): boolean
--- @field keymap blink.cmp.KeymapConfig
--- @field completion blink.cmp.CompletionConfig
--- @field fuzzy blink.cmp.FuzzyConfig
--- @field sources blink.cmp.SourceConfig
--- @field signature blink.cmp.SignatureConfig
--- @field snippets blink.cmp.SnippetsConfig
--- @field appearance blink.cmp.AppearanceConfig

local validate = require('blink.cmp.config.utils').validate
--- @type blink.cmp.ConfigStrict
local config = {
  enabled = function() return vim.bo.buftype ~= 'prompt' and vim.b.completion ~= false end,
  keymap = require('blink.cmp.config.keymap').default,
  completion = require('blink.cmp.config.completion').default,
  fuzzy = require('blink.cmp.config.fuzzy').default,
  sources = require('blink.cmp.config.sources').default,
  signature = require('blink.cmp.config.signature').default,
  snippets = require('blink.cmp.config.snippets').default,
  appearance = require('blink.cmp.config.appearance').default,
}

--- @type blink.cmp.ConfigStrict
--- @diagnostic disable-next-line: missing-fields
local M = {}

--- @param cfg blink.cmp.ConfigStrict
function M.validate(cfg)
  validate('config', {
    enabled = { cfg.enabled, 'function' },
    keymap = { cfg.keymap, 'table' },
    completion = { cfg.completion, 'table' },
    fuzzy = { cfg.fuzzy, 'table' },
    sources = { cfg.sources, 'table' },
    signature = { cfg.signature, 'table' },
    snippets = { cfg.snippets, 'table' },
    appearance = { cfg.appearance, 'table' },
  }, cfg)
  require('blink.cmp.config.keymap').validate(cfg.keymap)
  require('blink.cmp.config.completion').validate(cfg.completion)
  require('blink.cmp.config.fuzzy').validate(cfg.fuzzy)
  require('blink.cmp.config.sources').validate(cfg.sources)
  require('blink.cmp.config.signature').validate(cfg.signature)
  require('blink.cmp.config.snippets').validate(cfg.snippets)
  require('blink.cmp.config.appearance').validate(cfg.appearance)
end

--- @param user_config blink.cmp.Config
function M.merge_with(user_config)
  config = vim.tbl_deep_extend('force', config, user_config)
  M.validate(config)
end

return setmetatable(M, {
  __index = function(_, k) return config[k] end,
})
