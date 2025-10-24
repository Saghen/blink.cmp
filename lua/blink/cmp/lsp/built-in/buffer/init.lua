-- todo: nvim-cmp only updates the lines that got changed which is better
-- but this is *speeeeeed* and simple. should add the better way
-- but ensure it doesn't add too much complexity

local cmp = require('blink.cmp')
local async = require('blink.cmp.lib.async')
local parser = require('blink.cmp.sources.buffer.parser')
local utils = require('blink.cmp.sources.lib.utils')
local deduplicate = require('blink.cmp.lib.utils').deduplicate

local cache = require('blink.cmp.sources.buffer.cache')
local priority = require('blink.cmp.sources.buffer.priority')

--- @class blink.cmp.BufferOpts
--- @field get_bufnrs fun(): integer[]
--- @field max_total_buffer_size integer Maximum text size across all buffers (default: 500KB)

vim.lsp.config('buffer', {
  settings = {
    get_bufnrs = function()
      return vim
        .iter(vim.api.nvim_list_wins())
        :map(function(win) return vim.api.nvim_win_get_buf(win) end)
        :filter(function(buf) return vim.bo[buf].buftype ~= 'nofile' end)
        :totable()
    end,
    max_total_buffer_size = 500000,
  },

  cmd = cmp.lsp.server({
    capabilities = { completionProvider = {} },
    handlers = {
      ['textDocument/completion'] = function(_, _, callback)
        local opts = vim.lsp.config.buffer.settings.buffer
        --- @cast opts blink.cmp.BufferOpts

        local is_search_context = utils.is_command_line({ '/', '?' })
        if utils.is_command_line() and not is_search_context then
          callback()
          return
        end

        -- Select buffers
        local bufnrs = is_search_context and { vim.api.nvim_get_current_buf() } or deduplicate(opts.get_bufnrs())
        local selected_bufnrs = priority.retain_buffers(bufnrs, opts.max_total_buffer_size)
        if #selected_bufnrs == 0 then
          callback()
          return
        end

        -- Get words for each buffer
        local curr_bufnr = vim.api.nvim_get_current_buf()
        local tasks = vim.tbl_map(
          function(bufnr) return parser.get_buf_words(bufnr, curr_bufnr == bufnr and not is_search_context) end,
          selected_bufnrs
        )

        -- Deduplicate words and respond
        async.task.all(tasks):map(function(words_per_buf)
          --- @cast words_per_buf string[][]

          local unique = {}
          local words = {}
          for _, buf_words in ipairs(words_per_buf) do
            for _, word in ipairs(buf_words) do
              if not unique[word] then
                unique[word] = true
                table.insert(words, word)
              end
            end
          end

          cache.keep(selected_bufnrs)

          callback({
            isIncomplete = false,
            items = utils.words_to_items(words),
          })
        end)
      end,
    },
  }),
})
