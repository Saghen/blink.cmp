# Command line (cmdline)

By default, blink.cmp enabled cmdline completions (`cmdline.enabled = true`), matchiing the behavior of the built-in `cmdline` completion:

- Menu will not show automatically (`cmdline.completion.menu.auto_show = false`)
- Pressing `<Tab>` will show the completion menu and insert the first item
  - Subsequent `<Tab>`s will select the next item, `<S-Tab>` for previous item
- `<C-n>` for next item, `<C-p>` for previous item
- `<C-y>` accepts the current item
- `<C-e>` cancels the completion
- When [noice.nvim](https://github.com/folke/noice.nvim) is detected, ghost text will be shown, see the [ghost text](#ghost-text) section below

See the [reference configuration](../configuration/reference.md#cmdline) for the complete list of options.

## Keymap preset

Set via `cmdline.keymap.preset = 'cmdline'`, which is the default. Set to `'none'` to disable the preset. See the [keymap documentation](../configuration/keymap.md) for more information on defining your own.

```lua
{
  ['<Tab>'] = {
    function(cmp)
      if cmp.is_ghost_text_visible() and not cmp.is_menu_visible() then return cmp.accept() end
    end,
    'show_and_insert',
    'select_next',
  },
  ['<S-Tab>'] = { 'show_and_insert', 'select_prev' },

  ['<C-n>'] = { 'select_next' },
  ['<C-p>'] = { 'select_prev' },

  ['<C-y>'] = { 'select_and_accept' },
  ['<C-e>'] = { 'cancel' },
}
```

## Ghost text

When [noice.nvim](https://github.com/folke/noice.nvim) is detected, ghost text will be shown, likely similar to your terminal shell completions. Pressing `<Tab>` while ghost text is visible will accept the completion. When not visible, `<Tab>` will open the menu and insert the first item as per usual.

<img src="https://github.com/user-attachments/assets/b2fa6f41-4937-47bf-86b3-d82e9ec86b12">

```lua
cmdline = { completion = { ghost_text = { enabled = true } } }
```

## Show menu automatically

By default, the completion menu will not be shown automatically. You may set `cmdline.completion.menu.auto_show = true` to have it appear automatically.

```lua
cmdline = {
  keymap = {
    -- recommended, as the default keymap will only show and select the next item
    ['<Tab>'] = { 'show', 'accept' },
  },
  completion = { menu = { auto_show = true } },
}
```

However, you may want to only show the menu only when writing commands, and not when searching or using other input menus.

```lua
cmdline = {
  keymap = {
    -- recommended, as the default keymap will only show and select the next item
    ['<Tab>'] = { 'show', 'accept' },
  },
  completion = {
    menu = {
      auto_show = function(ctx)
        return vim.fn.getcmdtype() == ':'
        -- enable for inputs as well, with:
        -- or vim.fn.getcmdtype() == '@'
      end,
    },
  }
}
```

## Enter keymap

When using `<Enter>` (`<CR>`) to accept the current item, you may want to accept the completion item and immediately execute the command. You can achieve this via the `accept_and_enter` command. However, when writing abbreviations like `:wq`, with the menu automatically showing, you may end up accidentally accepting a completion item. Thus, you may disable the completions when the keyword, for the first argument, is less than 3 characters.

```lua
cmdline = {
  keymap = {
    ['<Tab>'] = { 'accept' },
    ['<CR>'] = { 'accept_and_enter', 'fallback' },
  },
  -- (optionally) automatically show the menu
  completion = { menu = { auto_show = true } }
},
sources = {
  providers = {
    cmdline = {
      min_keyword_length = function(ctx)
        -- when typing a command, only show when the keyword is 3 characters or longer
        if ctx.mode == 'cmdline' and string.find(ctx.line, ' ') == nil then return 3 end
        return 0
      end
    }
  }
}
```
