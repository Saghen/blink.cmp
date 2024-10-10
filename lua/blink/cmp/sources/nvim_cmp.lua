--- @class blink.cmp.Source
--- @field name string
--- @field opts table | nil
--- @field module table
local nvim_cmp = {}

function nvim_cmp.new(opts, name)
  local self = setmetatable(nvim_cmp, { _index = nvim_cmp })
  self.name = name
  self.opts = opts
  self.module = require('blink.cmp.sources.lib').nvim_cmp_registry:get_source(name)

  return self
end

function nvim_cmp:get_completions(ctx, callback)
  if self.module.complete == nil then
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

  if not self.module.complete(self.module, params, transformed_callback) then
    --- @diagnostic disable: missing-parameter
    return callback()
  end

  return function() end
end

function nvim_cmp:get_trigger_characters()
  --- @diagnostic disable: return-type-mismatch
  if self.module.get_trigger_characters == nil then return nil end
  return self.module:get_trigger_characters()
end

return nvim_cmp
