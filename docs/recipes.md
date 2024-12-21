# Recipes


## Disable per filetype

```lua
enabled = function()
  return not vim.tbl_contains({ "lua", "markdown" }, vim.bo.filetype)
    and vim.bo.buftype ~= "prompt"
    and vim.b.completion ~= false
end,
```

## Border

```lua
completion = {
  menu = { border = 'single' }
  documentation = { border = 'single' }
},
signature = { window = { border = 'single' } }
```

## Select Nth item from the list

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

## `mini.icons`

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

## Hide Copilot on suggestion

```lua
vim.api.nvim_create_autocmd('User', {
  pattern = 'BlinkCmpCompletionMenuOpen',
  callback = function()
    require("copilot.suggestion").dismiss()
    vim.b.copilot_suggestion_hidden = true
  end,
})

vim.api.nvim_create_autocmd('User', {
  pattern = 'BlinkCmpCompletionMenuClose',
  callback = function()
    vim.b.copilot_suggestion_hidden = false
  end,
})
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
  return ctx.trigger.kind == vim.lsp.protocol.CompletionTriggerKind.TriggerCharacter
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
