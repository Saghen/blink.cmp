-- credit to https://github.com/hrsh7th/cmp-path for the original implementation
-- and https://codeberg.org/FelipeLema/cmp-async-path for the async implementation

local path = {}
local NAME_REGEX = '\\%([^/\\\\:\\*?<>\'"`\\|]\\)'
local PATH_REGEX =
  assert(vim.regex(([[\%(\%(/PAT*[^/\\\\:\\*?<>\'"`\\| .~]\)\|\%(/\.\.\)\)*/\zePAT*$]]):gsub('PAT', NAME_REGEX)))

function path.new(opts)
  local self = setmetatable({}, { __index = path })

  opts = vim.tbl_deep_extend('keep', opts, {
    trailing_slash = false,
    label_trailing_slash = true,
    get_cwd = function(context) return vim.fn.expand(('#%d:p:h'):format(context.bufnr)) end,
    show_hidden_files_by_default = false,
  })
  vim.validate({
    trailing_slash = { opts.trailing_slash, 'boolean' },
    label_trailing_slash = { opts.label_trailing_slash, 'boolean' },
    get_cwd = { opts.get_cwd, 'function' },
    show_hidden_files_by_default = { opts.show_hidden_files_by_default, 'boolean' },
  })

  self.opts = opts or {}
  return self
end

function path:get_trigger_characters() return { '/', '.' } end

function path:get_completions(context, callback)
  local lib = require('blink.cmp.sources.path.lib')

  local dirname = lib.dirname(PATH_REGEX, self.opts.get_cwd, context)
  if not dirname then return callback() end

  local include_hidden = self.opts.show_hidden_files_by_default
    or string.sub(context.line, context.bounds.start_col - 1, context.bounds.start_col - 1) == '.'
  lib
    .candidates(dirname, include_hidden, self.opts)
    :map(
      function(candidates)
        callback({ is_incomplete_forward = false, is_incomplete_backward = true, items = candidates })
      end
    )
    :catch(function() callback() end)
end

return path
