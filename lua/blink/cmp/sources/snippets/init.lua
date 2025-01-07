local source = {}

function source.new(opts)
  local preset = opts.preset or require('blink.cmp.config').snippets.preset
  local module = 'blink.cmp.sources.snippets.' .. preset
  return require(module).new(opts)
end

return source
