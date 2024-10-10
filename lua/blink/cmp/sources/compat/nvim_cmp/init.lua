local registry = require('blink.cmp.sources.compat.nvim_cmp.registry')

--- @class blink.cmp.Source
--- @field name string
--- @field opts table | nil
--- @field source table
local nvim_cmp = {}

function nvim_cmp.new(opts, name)
  local self = setmetatable(nvim_cmp, { _index = nvim_cmp })
  self.name = name
  self.opts = opts

  return self
end

function nvim_cmp:get_completions(ctx, callback)
  local source = registry.get_source(self.name)
  if source == nil or source.complete == nil then
    --- @diagnostic disable: missing-parameter
    return callback()
  end

  local function transformed_callback(candidates)
    if candidates == nil then
      callback()
      return
    end

    -- todo: how to if know is_incomplete_forward and is_incomplete_backward?
    local is_incomplete = candidates.isIncomplete or false

    callback({
      context = ctx,
      is_incomplete_forward = is_incomplete,
      is_incomplete_backward = is_incomplete,
      items = candidates.items or candidates,
    })
  end

  local params = {
    name = self.name,
    option = self.opts or {},
    offset = ctx.cursor[2], -- todo: match nvim-cmp behavior more closely
    context = {
      bufnr = ctx.bufnr,
      cursor_before_line = string.sub(ctx.line, 1, ctx.cursor[2]),
    },
  }

  source:complete(params, transformed_callback)

  return function() end
end

function nvim_cmp:get_trigger_characters()
  local source = registry.get_source(self.name)
  --- @diagnostic disable: return-type-mismatch
  if source == nil or source.get_trigger_characters == nil then return {} end
  return source:get_trigger_characters()
end

function nvim_cmp:should_show_completions()
  local source = registry.get_source(self.name)
  if source == nil or source.is_available == nil then return true end
  return source:is_available()
end

return nvim_cmp
