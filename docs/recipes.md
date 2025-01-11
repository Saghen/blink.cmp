# Recipes

[[toc]]

## General

### Disable per filetype

```lua
enabled = function()
  return not vim.tbl_contains({ "lua", "markdown" }, vim.bo.filetype)
    and vim.bo.buftype ~= "prompt"
    and vim.b.completion ~= false
end,
```

### Border

```lua
completion = {
  menu = { border = 'single' },
  documentation = { window = { border = 'single' } },
},
signature = { window = { border = 'single' } },
```

### Change selection type per mode

```lua
completion = { 
  list = { 
    selection = {
      preselect = function(ctx) return ctx.mode ~= 'cmdline' end,
      auto_insert = function(ctx) return ctx.mode ~= 'cmdline' end
    }
  }
}
```

### Buffer completion from all open buffers

The default behavior is to only show completions from **visible** "normal" buffers (i.e. it woudldn't include neo-tree). This will instead show completions from all buffers, even if they're not visible on screen. Note that the performance impact of this has not been tested. 

```lua
sources = {
  providers = {
    buffer = {
      opts = {
        -- get all buffers, even ones like neo-tree
        get_bufnrs = vim.api.nvim_list_bufs
        -- or (recommended) filter to only "normal" buffers
        get_bufnrs = function()
          return vim.tbl_filter(function(bufnr)
            return vim.bo[bufnr].buftype == ''
          end, vim.api.nvim_list_bufs())
        end
      }
    }
  }
}
```

### Don't show completion menu automatically in cmdline mode

```lua
completion = { 
  menu = { auto_show = function(ctx) return ctx.mode ~= 'cmdline' end }
}
```

### Don't show completion menu automatically when searching

```lua
completion = {
  menu = {
    auto_show = function(ctx)
      return ctx.mode ~= "cmdline" or not vim.tbl_contains({ '/', '?' }, vim.fn.getcmdtype())
    end,
  },
}
```

### Select Nth item from the list

Here's an example configuration that allows you to select the nth item from the list, based on [#382](https://github.com/Saghen/blink.cmp/issues/382):

```lua
keymap = {
  preset = 'default',
  ['<A-1>'] = { function(cmp) cmp.accept({ index = 1 }) end },
  ['<A-2>'] = { function(cmp) cmp.accept({ index = 2 }) end },
  ['<A-3>'] = { function(cmp) cmp.accept({ index = 3 }) end },
  ['<A-4>'] = { function(cmp) cmp.accept({ index = 4 }) end },
  ['<A-5>'] = { function(cmp) cmp.accept({ index = 5 }) end },
  ['<A-6>'] = { function(cmp) cmp.accept({ index = 6 }) end },
  ['<A-7>'] = { function(cmp) cmp.accept({ index = 7 }) end },
  ['<A-8>'] = { function(cmp) cmp.accept({ index = 8 }) end },
  ['<A-9>'] = { function(cmp) cmp.accept({ index = 9 }) end },
  ['<A-0>'] = { function(cmp) cmp.accept({ index = 10 }) end },
},
completion = {
  menu = {
    draw = {
      columns = { { 'item_idx' }, { 'kind_icon' }, { 'label', 'label_description', gap = 1 } },
      components = {
        item_idx = {
          text = function(ctx) return ctx.idx == 10 and '0' or ctx.idx >= 10 and ' ' or tostring(ctx.idx) end,
          highlight = 'BlinkCmpItemIdx' -- optional, only if you want to change its color
        }
      }
    }
  }
}
```

### `mini.icons`

[Original discussion](https://github.com/Saghen/blink.cmp/discussions/458)

```lua
completion = {
  menu = {
    draw = {
      components = {
        kind_icon = {
          ellipsis = false,
          text = function(ctx)
            local kind_icon, _, _ = require('mini.icons').get('lsp', ctx.kind)
            return kind_icon
          end,
          -- Optionally, you may also use the highlights from mini.icons
          highlight = function(ctx)
            local _, hl, _ = require('mini.icons').get('lsp', ctx.kind)
            return hl
          end,
        }
      }
    }
  }
}
```

### Hide Copilot on suggestion

```lua
vim.api.nvim_create_autocmd('User', {
  pattern = 'BlinkCmpMenuOpen',
  callback = function()
    require("copilot.suggestion").dismiss()
    vim.b.copilot_suggestion_hidden = true
  end,
})

vim.api.nvim_create_autocmd('User', {
  pattern = 'BlinkCmpMenuClose',
  callback = function()
    vim.b.copilot_suggestion_hidden = false
  end,
})
```

### Show on newline, tab and space

Note that you may want to add the override to other sources as well, since if the LSP doesnt return any items, we won't show the menu if it was triggered by any of these three characters.

```lua
-- by default, blink.cmp will block newline, tab and space trigger characters, disable that behavior
completion.trigger.blocked_trigger_characters = {}

-- add newline, tab and space to LSP source trigger characters
sources.providers.lsp.override.get_trigger_characters = function(self)
  local trigger_characters = self:get_trigger_characters()
  vim.list_extend(trigger_characters, { '\n', '\t', ' ' })
  return trigger_characters
end
```

## Sources

### Dynamically picking providers by treesitter node/filetype

```lua
sources.default = function(ctx)
  local success, node = pcall(vim.treesitter.get_node)
  if vim.bo.filetype == 'lua' then
    return { 'lsp', 'path' }
  elseif success and node and vim.tbl_contains({ 'comment', 'line_comment', 'block_comment' }, node:type()) then
    return { 'buffer' }
  else
    return { 'lsp', 'path', 'snippets', 'buffer' }
  end
end
```

### Hide snippets after trigger character

> [!NOTE]
> Untested, might not work well, please open a PR if you find a better solution!

Trigger characters are defined by the sources. For example, for Lua, the trigger characters are `.`, `"`, `'`.

```lua
sources.providers.snippets.should_show_items = function(ctx)
  return ctx.trigger.initial_kind ~= 'trigger_character'
end
```

### Disable all snippets

See the [relevant section in the snippets documentation](./configuration/snippets.md#disable-all-snippets)

### Set minimum keyword length by filetype

```lua
sources.min_keyword_length = function()
  return vim.bo.filetype == 'markdown' and 2 or 0
end
```

## For writers

When writing prose, you may want significantly different behavior than typical LSP completions. If you find any interesting configurations, please open a PR adding it here!

### Keep first letter capitalization on buffer source

```lua
sources = {
  providers = {
    buffer = {
      -- keep case of first char
      transform_items = function (a, items)
        local keyword = a.get_keyword()
        local correct, case
        if keyword:match('^%l') then
            correct = '^%u%l+$'
            case = string.lower
        elseif keyword:match('^%u') then
            correct = '^%l+$'
            case = string.upper
        else
            return items
        end

        -- avoid duplicates from the corrections
        local seen = {}
        local out = {}
        for _, item in ipairs(items) do
            local raw = item.insertText
            if raw:match(correct) then
                local text = case(raw:sub(1,1)) .. raw:sub(2)
                item.insertText = text
                item.label = text
            end
            if not seen[item.insertText] then
                seen[item.insertText] = true
                table.insert(out, item)
            end
        end
        return out
      end
    }
  }
}
```
