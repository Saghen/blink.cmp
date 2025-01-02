# Completion

Blink cmp has *a lot* of configuration options, the following document tries to highlight the ones you'll likely care the most about for each section. For all options, click on the "Go to default configuration" button next to each header.

## Keyword <a href="./reference#completion-keyword"><Badge type="info" text="Go to default configuration" /></a>

Controls what the plugin considers to be a keyword, used for fuzzy matching and triggering completions. Most notably, the `range` option controls whether the keyword should match against the text before *and* after the cursor, or just before the cursor.

:::tabs
== Prefix
<img src="https://github.com/user-attachments/assets/6398e470-58c7-4624-989a-bffe26c7f443" />
== Full
<img src="https://github.com/user-attachments/assets/3e082492-6a5d-4dba-b4ba-6a1bfca50351" />
:::

## Trigger <a href="./reference#completion-trigger"><Badge type="info" text="Go to default configuration" /></a>

Controls when to request completion items from the sources and show the completion menu. The following options are available, excluding their `show_on` prefix:

:::tabs
== Keyword
Shows after typing a keyword, typically an alphanumeric character, `-` or `_`

```lua
completion.trigger.show_on_keyword = true
```

<video src="https://github.com/user-attachments/assets/5e8f8f9f-bc6a-4d21-9cce-2e291b6a7de8" muted autoplay loop />
== Trigger Character

Shows after typing a trigger character, defined by the sources. For example for Lua or Rust, the LSP will define `.` as a trigger character.

```lua
completion.trigger.show_on_trigger_character = true
```

<video src="https://github.com/user-attachments/assets/b4ee0069-2de8-44e7-b3ca-51b10bc4cb4a" muted autoplay loop />
== Insert on Trigger Character

Shows after entering insert mode on top of a trigger character.

```lua
completion.trigger.show_on_insert_on_trigger_character = true
```

<video src="https://github.com/user-attachments/assets/9e7aa3c2-4756-4a5e-a0e8-303d3ae0fda9" muted autoplay loop />
== Accept on Trigger Character

Shows after accepting a completion item, where the cursor ends up on top of a trigger character.

```lua
completion.trigger.show_on_accept_on_trigger_character = true
```

TODO: Find a case where this actually fires : )
:::

## List <a href="./reference#completion-list"><Badge type="info" text="Go to default configuration" /></a>

Manages the completion list and its behavior when selecting items. The most commonly changed option is `completion.list.selection`, which controls whether the list will automatically select the first item in the list, and whether selection shows a preview:

To control the selection behavior per mode, pass a function to `completion.list.selection` that returns the selection mode:

```lua
completion.list.selection = 'preselect'
-- or
completion.list.selection = function(ctx)
  return ctx.mode == 'cmdline' and 'auto_insert' or 'preselect'
end
```

:::tabs
== Preselect
Selects the first item automatically

<img src="https://github.com/user-attachments/assets/69079ced-43f1-437e-8a45-3cb13f841d61" />
== Manual
No item will be selected by default. You may use the `select_and_accept` keymap command to select the first item and accept it when there's no selection. The `accept` keymap command, on the other hand, will only trigger if an item is selected.

<video src="https://github.com/user-attachments/assets/09cd9b4b-18b3-456b-bb0a-074ae54e9d77" muted autoplay loop />
== Auto Insert
No item will be selected by default, and selecting an item will insert a "preview" of the item automatically. You may use the `select_and_accept` keymap command to select the first item and accept it when there's no selection. The `accept` keymap command, on the other hand, will only trigger if an item is selected.

<video src="https://github.com/user-attachments/assets/4658b61d-1b95-404a-b6b5-3a4afbfb8112" muted autoplay loop />
:::

## Accept <a href="./reference#completion-accept"><Badge type="info" text="Go to default configuration" /></a>

Manages the behavior when accepting an item in the completion menu.

### Auto Brackets

> [!NOTE]
> Some LSPs may add auto brackets themselves. You may be able to configure this behavior in your LSP client configuration

LSPs provide a `kind` field for completion items, indicating whether the item is a function, method, variable, etc. The plugin will automatically add brackets for functions/methods and place the cursor inside the brackets. For items not marked as such, the plugin will asynchronously resolve the semantic tokens from the LSP and add brackets if marked as a function. A default list of brackets have been included in the default configuration, but you may add more in the configuration (contributions welcome!).

If brackets are showing when you don't expect them, try disabling `kind_resolution` or `semantic_token_resolution` for that filetype (`echo &filetype`). If that fixes the issue, please open a PR setting this as the default!

## Menu <a href="./reference#completion-menu"><Badge type="info" text="Go to default configuration" /></a>

Manages the appearance of the completion menu. You may prevent the menu from automatically showing by setting `completion.menu.auto_show = false` and manually showing it with the `show` keymap command.

### Menu Draw <a href="./reference#completion-menu-draw"><Badge type="info" text="Go to default configuration" /></a>

blink.cmp uses a grid-based layout to render the completion menu. The components, defined in `draw.components[string]`, define `text` and `highlight` functions which are called for each completion item. The `highlight` function will be called only when the item appears on screen, so expensive operations such as Treesitter highlighting may be performed (contributions welcome!, [for example](https://www.reddit.com/r/neovim/comments/1ca4gm2/colorful_cmp_menu_powered_by_treesitter/)). The components may define their min and max width, where `ellipsis = true` (enabled by default), will draw the `…` character when the text is truncated. Setting `width.fill = true` will fill the remaining space, effectively making subsequent components right aligned, with respect to their column.

Columns effectively allow you to vertically align a set of components. Each column, defined as an array in `draw.columns`, will be rendered for all of the completion items, where the longest rendered row will determine the width of the column. You may define `gap = number` in your column to insert a gap between components.

For a setup similar to nvim-cmp, use the following config:

```lua
completion.menu.draw.columns = { { "label", "label_description", gap = 1 }, { "kind_icon", "kind" } },
```

### Treesitter

You may use treesitter to highlight the label text for the given list of sources. This feature is experimental, contributions welcome!

```lua
completion.menu.draw.treesitter = { 'lsp' }
```

## Documentation <a href="./reference#completion-documentation"><Badge type="info" text="Go to default configuration" /></a>

By default, the documentation window will only show when triggered by the `show_documentation` keymap command. However, you may add the following configuration to show the documentation whenever an item is selected.

```lua
completion.documentation = {
  auto_show = true,
  auto_show_delay_ms = 500,
}
```

If you're noticing high CPU usage or stuttering when opening the documentation, you may try setting `completion.documentation.treesitter_highlighting = false`.

## Ghost Text <a href="./reference#completion-ghost-text"><Badge type="info" text="Go to default configuration" /></a>

Ghost text shows a preview of the currently selected item as virtual text inline. You may want to try setting `completion.menu.auto_show = false` and enabling ghost text, or you may use both in parallel. 

```lua
completion.ghost_text.enabled = true
```

<img src="https://github.com/user-attachments/assets/1d30ef90-3ba4-43ca-a1a6-faa70f830e17" />
