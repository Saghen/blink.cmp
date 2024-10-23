--- @class blink.cmp.SourceProviderConfigWrapper
--- @field new fun(config: blink.cmp.SourceProviderConfig): blink.cmp.SourceProviderConfigWrapper
--- @field name string
--- @field module string
--- @field enabled fun(ctx: blink.cmp.Context): boolean
--- @field transform_items fun(ctx: blink.cmp.Context, items: blink.cmp.CompletionItem[]): blink.cmp.CompletionItem[]
--- @field should_show_items fun(ctx: blink.cmp.Context, items: blink.cmp.CompletionItem[]): boolean
--- @field max_items? fun(ctx: blink.cmp.Context, enabled_sources: string[], items: blink.cmp.CompletionItem[]): number
--- @field min_keyword_length fun(ctx: blink.cmp.Context, enabled_sources: string[]): number
--- @field fallback_for fun(ctx: blink.cmp.Context, enabled_sources: string[]): string[]
--- @field score_offset fun(ctx: blink.cmp.Context, enabled_sources: string[]): number

--- @class blink.cmp.SourceProviderConfig
--- @diagnostic disable-next-line: missing-fields
local wrapper = {}

function wrapper.new(config)
  local function call_or_get(fn_or_val, default)
    if fn_or_val == nil then return function() return default end end
    return function(...)
      if type(fn_or_val) == 'function' then return fn_or_val(...) end
      return fn_or_val
    end
  end

  local self = setmetatable({}, { __index = config })
  self.name = config.name
  self.module = config.module
  self.enabled = call_or_get(config.enabled, true)
  self.transform_items = config.transform_items or function(_, items) return items end
  self.should_show_items = call_or_get(config.should_show_items, true)
  self.max_items = call_or_get(config.max_items, nil)
  self.min_keyword_length = call_or_get(config.min_keyword_length, 0)
  self.fallback_for = call_or_get(config.fallback_for, {})
  self.score_offset = call_or_get(config.score_offset, 0)
  return self
end

return wrapper
