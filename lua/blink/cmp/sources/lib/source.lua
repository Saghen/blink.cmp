local source = {}

--- @param config blink.cmp.SourceProviderConfig
--- @return blink.cmp.SourceProvider
function source.new(config)
  local self = setmetatable({}, { __index = source })
  self.module = require(config[1]).new(config.opts or {})

  self.fallback_for = config.fallback_for
  self.keyword_length = config.keyword_length
  self.score_offset = config.score_offset
  self.deduplicate = config.deduplicate
  self.override = config.override or {}

  return self
end

function source:get_trigger_characters()
  if self.override.get_trigger_characters ~= nil then
    return self.override.get_trigger_characters(self.module.get_trigger_characters)
  end
  if self.module.get_trigger_characters == nil then return {} end
  return self.module.get_trigger_characters()
end

function source:completions(context, callback)
  if self.override.completions ~= nil then
    return self.override.completions(context, callback, self.module.completions)
  end
  self.module.completions(context, callback)
end

function source:filter_completions(context, source_responses)
  if self.override.filter_completions ~= nil then
    return self.override.filter_completions(context, source_responses, self.module.filter_completions)
  end
  if self.module.filter_completions == nil then return source_responses end
  return self.module.filter_completions(context, source_responses)
end

function source:resolve(item, callback)
  if self.override.resolve ~= nil then return self.override.resolve(item, callback, self.module.resolve) end
  if self.module.resolve == nil then return callback(item) end
  self.module.resolve(item, callback)
end

function source:cancel_completions()
  if self.override.cancel_completions ~= nil then
    return self.override.cancel_completions(self.module.cancel_completions)
  end
  if self.module.cancel_completions == nil then return end
  self.module.cancel_completions()
end

return source
