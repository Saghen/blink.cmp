-- credit to https://github.com/hrsh7th/cmp-path for the original implementation
-- and https://codeberg.org/FelipeLema/cmp-async-path for the async implementation

-- TODO: more advanced detection of windows vs unix paths to resolve escape sequences
-- like "Android\ Camera", which currently returns no items

--- @class blink.cmp.PathOpts
--- @field trailing_slash boolean
--- @field label_trailing_slash boolean
--- @field get_cwd fun(context: blink.cmp.Context): string
--- @field show_hidden_files_by_default boolean
--- @field ignore_root_slash boolean

vim.lsp.config('path', {
  settings = {
    trailing_slash = true,
    label_trailing_slash = true,
    get_cwd = function(context) return vim.fn.expand(('#%d:p:h'):format(context.bufnr)) end,
    show_hidden_files_by_default = false,
    ignore_root_slash = false,
  },

  cmd = cmp.lsp.server({
    capabilities = {
      completionProvider = {
        triggerCharacters = { '/', '.', '\\' },
        resolveProvider = true,
      },
    },
    handlers = {
      ['textDocument/completion'] = function(_, _, callback)
        local opts = vim.lsp.config.path.settings.path
        --- @cast opts blink.cmp.PathOpts

        -- we use libuv, but the rest of the library expects to be synchronous
        callback = vim.schedule_wrap(callback)

        local lib = require('blink.cmp.sources.path.lib')

        local dirname = lib.dirname(opts, context)
        if not dirname then return callback(nil, { isIncomplete = false, items = {} }) end

        local include_hidden = self.opts.show_hidden_files_by_default
          or (string.sub(context.line, context.bounds.start_col, context.bounds.start_col) == '.' and context.bounds.length == 0)
          or (
            string.sub(context.line, context.bounds.start_col - 1, context.bounds.start_col - 1) == '.'
            and context.bounds.length > 0
          )
        lib
          .candidates(context, dirname, include_hidden, self.opts)
          :map(function(candidates) callback(nil, { isIncomplete = false, items = candidates }) end)
          :catch(function(err) callback(err) end)
      end,

      ['completionItem/resolve'] = function(_, item, callback)
        require('blink.cmp.sources.path.fs')
          .read_file(item.data.full_path, 1024)
          :map(function(content)
            local is_binary = content:find('\0')

            -- binary file
            if is_binary then
              item.documentation = {
                kind = 'plaintext',
                value = 'Binary file',
              }
            -- highlight with markdown
            else
              local ext = vim.fn.fnamemodify(item.data.path, ':e')
              item.documentation = {
                kind = 'markdown',
                value = '```' .. ext .. '\n' .. content .. '```',
              }
            end

            return item
          end)
          :map(function(resolved_item) callback(resolved_item) end)
          :catch(function() callback(item) end)
      end,
    },
  }),
})
