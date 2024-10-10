--- @class blink.cmp.Source
--- @field name string
--- @field opts table | nil
--- @field source table
local nvim_cmp = {}

function nvim_cmp.new(opts, name)
  local self = setmetatable(nvim_cmp, { _index = nvim_cmp })
  self.name = name
  self.opts = opts
  self.source = require('blink.cmp.sources.lib').nvim_cmp_registry:get_source(name)

  return self
end

function nvim_cmp:get_completions(ctx, callback)
  if self.source.complete == nil then
    --- @diagnostic disable: missing-parameter
    return callback()
  end

  local function transformed_callback(candidates)
    if not candidates then return false end
    -- todo: how to if know is_incomplete_forward and is_incomplete_backward?
    callback({
      context = ctx,
      is_incomplete_forward = false,
      is_incomplete_backward = false,
      items = candidates,
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

  if not self.source.complete(self.source, params, transformed_callback) then
    --- @diagnostic disable: missing-parameter
    return callback()
  end

  return function() end
end

function nvim_cmp:get_trigger_characters()
  --- @diagnostic disable: return-type-mismatch
  if self.source.get_trigger_characters == nil then return nil end
  return self.source:get_trigger_characters()
end

function nvim_cmp:should_show_completions()
  if self.source.is_available == nil then return true end
  return self.source:is_available()
end

return nvim_cmp
