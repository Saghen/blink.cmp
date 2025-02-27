# Keymap

Blink uses a special schema for defining keymaps since it needs to handle falling back to other mappings. However, there's nothing stopping you from using `require('blink.cmp')` and implementing these keymaps yourself.

Your custom key mappings are merged with a `preset` and any conflicting keys will overwrite the preset mappings. The `fallback` command will run the next non blink keymap.

## Example

::: warning
These keymaps apply to the default mode only, not cmdline or terminal modes. See the [cmdline](../modes/cmdline.md) and [term](../modes/term.md) documentation for more information.
:::

Each keymap may be a list of commands and/or functions, where commands map directly to `require('blink.cmp')[command]()`. If the command/function returns `false` or `nil`, the next command/function will be run.

```lua
keymap = {
  -- set to 'none' to disable the 'default' preset
  preset = 'default',

  ['<Up>'] = { 'select_prev', 'fallback' },
  ['<Down>'] = { 'select_next', 'fallback' },

  -- disable a keymap from the preset
  ['<C-e>'] = {},
  
  -- show with a list of providers
  ['<C-space>'] = { function(cmp) cmp.show({ providers = { 'snippets' } }) end },

  -- control whether the next command will be run when using a function
  ['<C-n>'] = { 
    function(cmp)
      if some_condition then return end -- runs the next command
      return true -- doesn't run the next command
    end,
    'select_next'
  },
}
```

## Commands

- `show`: Shows the completion menu
  - Optionally use `function(cmp) cmp.show({ providers = { 'snippets' } }) end` to show with a specific list of providers
- `hide`: Hides the completion menu
- `cancel`: Reverts `completion.list.selection.auto_insert` and hides the completion menu
- `accept`: Accepts the currently selected item
  - Optionally pass an index to select a specific item in the list: `function(cmp) cmp.accept({ index = 1 }) end`
  - Optionally pass a `callback` to run after the item is accepted: `function(cmp) cmp.accept({ callback = function() some_function() end`
- `accept_and_enter`: Accepts the currently selected item and feeds an enter key to neovim
  - Useful in `cmdline` mode to accept the current item and run the command
- `select_and_accept`: Accepts the currently selected item, or the first item if none are selected
- `select_accept_and_enter`: Accepts the currently selected item, or the first item if none are selected, and feeds an enter key to neovim
  - Useful in `cmdline` mode to accept the current item and run the command
- `select_prev`: Selects the previous item, cycling to the bottom of the list if at the top, if `completion.list.cycle.from_top == true`
  - Optionally control the `auto_insert` property of `completion.list.selection`: `function(cmp) cmp.select_prev({ auto_insert = false }) end`
- `select_next`: Selects the next item, cycling to the top of the list if at the bottom, if `completion.list.cycle.from_bottom == true`
  - Optionally control the `auto_insert` property of `completion.list.selection`: `function(cmp) cmp.select_next({ auto_insert = false }) end`
- `show_documentation`: Shows the documentation for the currently selected item
- `hide_documentation`: Hides the documentation
- `scroll_documentation_up`: Scrolls the documentation up by 4 lines
  - Optionally use `function(cmp) cmp.scroll_documentation_up(4) end` to scroll by a specific number of lines
- `scroll_documentation_down`: Scrolls the documentation down by 4 lines
  - Optionally use `function(cmp) cmp.scroll_documentation_down(4) end` to scroll by a specific number of lines
- `show_signature`: Shows the signature help window
- `hide_signature`: Hides the signature help window
- `snippet_forward`: Jumps to the next snippet placeholder
- `snippet_backward`: Jumps to the previous snippet placeholder
- `fallback`: Runs the next non-blink keymap, or runs the built-in neovim binding
- `fallback_to_mappings`: Runs the next non-blink keymap (not built-in behavior)

## Cmdline and Terminal

See the respective [cmdline documentation](../modes/cmdline.md) and [terminal documentation](../modes/term.md) for more information.

## Presets

Set the preset to `'none'` to disable the presets

### `default`

```lua
['<C-space>'] = { 'show', 'show_documentation', 'hide_documentation' },
['<C-e>'] = { 'hide' },
['<C-y>'] = { 'select_and_accept' },

['<Up>'] = { 'select_prev', 'fallback' },
['<Down>'] = { 'select_next', 'fallback' },
['<C-p>'] = { 'select_prev', 'fallback_to_mappings' },
['<C-n>'] = { 'select_next', 'fallback_to_mappings' },

['<C-b>'] = { 'scroll_documentation_up', 'fallback' },
['<C-f>'] = { 'scroll_documentation_down', 'fallback' },

['<Tab>'] = { 'snippet_forward', 'fallback' },
['<S-Tab>'] = { 'snippet_backward', 'fallback' },

['<C-k>'] = { 'show_signature', 'hide_signature', 'fallback' },
```

### `cmdline`

See the [cmdline documentation](../modes/cmdline.md)

### `super-tab`

You may want to set `completion.trigger.show_in_snippet = false` or use `completion.list.selection.preselect = function(ctx) return not require('blink.cmp').snippet_active({ direction = 1 }) end`. See more info in: https://cmp.saghen.dev/configuration/completion.html#list

```lua
['<C-space>'] = { 'show', 'show_documentation', 'hide_documentation' },
['<C-e>'] = { 'hide', 'fallback' },

['<Tab>'] = {
  function(cmp)
    if cmp.snippet_active() then return cmp.accept()
    else return cmp.select_and_accept() end
  end,
  'snippet_forward',
  'fallback'
},
['<S-Tab>'] = { 'snippet_backward', 'fallback' },

['<Up>'] = { 'select_prev', 'fallback' },
['<Down>'] = { 'select_next', 'fallback' },
['<C-p>'] = { 'select_prev', 'fallback_to_mappings' },
['<C-n>'] = { 'select_next', 'fallback_to_mappings' },

['<C-b>'] = { 'scroll_documentation_up', 'fallback' },
['<C-f>'] = { 'scroll_documentation_down', 'fallback' },

['<C-k>'] = { 'show_signature', 'hide_signature', 'fallback' },
```

### `enter`

You may want to set `completion.list.selection.preselect = false`. See more info in: https://cmp.saghen.dev/configuration/completion.html#list

```lua
['<C-space>'] = { 'show', 'show_documentation', 'hide_documentation' },
['<C-e>'] = { 'hide', 'fallback' },
['<CR>'] = { 'accept', 'fallback' },

['<Tab>'] = { 'snippet_forward', 'fallback' },
['<S-Tab>'] = { 'snippet_backward', 'fallback' },

['<Up>'] = { 'select_prev', 'fallback' },
['<Down>'] = { 'select_next', 'fallback' },
['<C-p>'] = { 'select_prev', 'fallback_to_mappings' },
['<C-n>'] = { 'select_next', 'fallback_to_mappings' },

['<C-b>'] = { 'scroll_documentation_up', 'fallback' },
['<C-f>'] = { 'scroll_documentation_down', 'fallback' },

['<C-k>'] = { 'show_signature', 'hide_signature', 'fallback' },
```
