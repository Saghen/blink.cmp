--- @class (exact) blink.cmp.CompletionAcceptConfig
--- @field dot_repeat boolean Write completions to the `.` register
--- @field create_undo_point boolean Create an undo point when accepting a completion item
--- @field resolve_timeout_ms number How long to wait for the LSP to resolve the item with additional information before continuing as-is
--- @field auto_brackets blink.cmp.AutoBracketsConfig

--- @class (exact) blink.cmp.AutoBracketsConfig
--- @field enabled boolean Whether to auto-insert brackets for functions
--- @field default_brackets string[] Default brackets to use for unknown languages
--- @field override_brackets_for_filetypes table<string, string[] | fun(item: blink.cmp.CompletionItem): string[]>
--- @field force_allow_filetypes string[] Overrides the default blocked filetypes
--- @field blocked_filetypes string[]
--- @field kind_resolution blink.cmp.AutoBracketResolutionConfig Synchronously use the kind of the item to determine if brackets should be added
--- @field semantic_token_resolution blink.cmp.AutoBracketSemanticTokenResolutionConfig Asynchronously use semantic token to determine if brackets should be added

--- @class (exact) blink.cmp.AutoBracketResolutionConfig
--- @field enabled boolean
--- @field blocked_filetypes string[]

--- @class (exact) blink.cmp.AutoBracketSemanticTokenResolutionConfig
--- @field enabled boolean
--- @field blocked_filetypes string[]
--- @field timeout_ms number How long to wait for semantic tokens to return before assuming no brackets should be added

local validate = require('blink.cmp.config.utils').validate
local accept = {
  --- @type blink.cmp.CompletionAcceptConfig
  default = {
    dot_repeat = true,
    create_undo_point = true,
    resolve_timeout_ms = 100,
    auto_brackets = {
      enabled = true,
      default_brackets = { '(', ')' },
      override_brackets_for_filetypes = {},
      force_allow_filetypes = {},
      blocked_filetypes = {},
      kind_resolution = {
        enabled = true,
        blocked_filetypes = { 'typescriptreact', 'javascriptreact', 'vue' },
      },
      semantic_token_resolution = {
        enabled = true,
        blocked_filetypes = { 'java' },
        timeout_ms = 400,
      },
    },
  },
}

function accept.validate(config)
  validate('completion.accept', {
    dot_repeat = { config.dot_repeat, 'boolean' },
    create_undo_point = { config.create_undo_point, 'boolean' },
    resolve_timeout_ms = { config.resolve_timeout_ms, 'number' },
    auto_brackets = { config.auto_brackets, 'table' },
  }, config)
  validate('completion.accept.auto_brackets', {
    enabled = { config.auto_brackets.enabled, 'boolean' },
    default_brackets = { config.auto_brackets.default_brackets, 'table' },
    override_brackets_for_filetypes = { config.auto_brackets.override_brackets_for_filetypes, 'table' },
    force_allow_filetypes = { config.auto_brackets.force_allow_filetypes, 'table' },
    blocked_filetypes = { config.auto_brackets.blocked_filetypes, 'table' },
    kind_resolution = { config.auto_brackets.kind_resolution, 'table' },
    semantic_token_resolution = { config.auto_brackets.semantic_token_resolution, 'table' },
  }, config.auto_brackets)
  validate('completion.accept.auto_brackets.kind_resolution', {
    enabled = { config.auto_brackets.kind_resolution.enabled, 'boolean' },
    blocked_filetypes = { config.auto_brackets.kind_resolution.blocked_filetypes, 'table' },
  }, config.auto_brackets.kind_resolution)
  validate('completion.accept.auto_brackets.semantic_token_resolution', {
    enabled = { config.auto_brackets.semantic_token_resolution.enabled, 'boolean' },
    blocked_filetypes = { config.auto_brackets.semantic_token_resolution.blocked_filetypes, 'table' },
    timeout_ms = { config.auto_brackets.semantic_token_resolution.timeout_ms, 'number' },
  }, config.auto_brackets.semantic_token_resolution)
end

return accept
