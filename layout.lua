--[[
V2 Overall goals:
  - Adopt vim.task: https://github.com/lewis6991/async.nvim
  - First-class vim help documentation
  - Adopt `iskeyword` for keyword regex by default
  - Synchronous API when possible
  - Remove sources in favor of LSPs
    - Include compat layer for existing blink.cmp sources to in-process LSPs
    - Promote building in-process LSPs across the ecosystem (include boilerplate)
  - Simplify codebase as much as possible
    - Consider removing auto brackets, LSPs should support this themselves
    - Switch keymap system to `vim.on_key`
    - User calls `cmp.download()` to download prebuilt-binaries or `cmp.build()` to build from source. No automatic download
    - Drop custom documentation rendering, in favor of vim.lsp.utils.convert_input_to_markdown_lines (we have conceal lines now!)
    - Adopt scrollbar when it's merged: https://github.com/neovim/neovim/pull/35729

Configuration goals:
  - Programmatic over declarative
  - Follow neovim patterns as much as possible (refer to vim.lsp.*, vim.lsp.inlay_hint.*, etc.)
  - Easily configure per-buffer, per-LSP, and dynamically
  - First-class vim.pack support
  - All on_* event handlers also emit `User` autocommands
--]]

--- @alias filter { bufnr: number?, mode: '*' | ('default' | 'cmdline' | 'term')[] | nil }

local cmp = require('blink.cmp')

-- seek community adoption
vim.g.completion = true -- or vim.b.completion
vim.g.nerd_font_variant = 'mono' -- for 'normal', icons are double-width
vim.g.lsp_item_kind_icons = { Text = '󰉿', ... }

-- blink specific, supports `vim.b` too
vim.g.blink_cmp = true -- equivalent to vim.g.completion, but takes precedence

--- Global ---
cmp.enable(enable?, filter?) -- enabled by default
cmp.is_enabled(filter?)

cmp.show({ lsps = {}, select_item_idx = nil }) -- vim.Task
cmp.hide()

cmp.accept({ select = false, index = nil }) -- vim.Task
cmp.select_next({ count = 1, cycle = true, preview = true })
cmp.select_prev({ count = 1, cycle = true, preview = true })
cmp.select(idx, { preview = true })

--- Keymaps ---
-- now optional, since users can define keymaps themselves and use the (mostly) synchronous `cmp.*` API
-- filter excludes modes
cmp.keymap.preset(mode, preset, filter?) -- cmp.keymap.preset('*', 'tab')
cmp.keymap.set(mode, key, function(cmp) ... end, filter?)
cmp.keymap.del(mode, key, filter?)

cmp.keymap.enable(enable?, filter?) -- enabled by default, but no keybinds are assigned
cmp.keymap.is_enabled(filter?)

--- Completion ---
---- Trigger ----
cmp.trigger.config({
  keyword = { range = 'prefix', regex = nil },
  on_keyword = true,
  on_trigger_character = true,
  on_accept_on_trigger_character = true,
  on_insert_enter_on_trigger_character = true,
}, filter?)
cmp.trigger.enable(enable?, filter?) -- enabled by default
cmp.trigger.is_enabled(filter?)

cmp.trigger.on_show(function(ctx) end)
cmp.trigger.on_hide(function(ctx) end)

---- List ----
cmp.list.config({
  preselect = true,
  sorts = { 'score', 'sort_text' },
  filters = { function(item) return item.label == 'foo' end },
  fuzzy = cmp.fuzzy.rust({
    max_typos = function(keyword) return math.floor(#keyword / 4) end,
    frecency_path = vim.fn.stdpath('state') .. '/blink/cmp/frecency.dat',
  }),
}, filter?) -- ephemeral option? e.g. could set the sort/filter options for a single completion context

cmp.list.get_items()
cmp.list.get_selected_item()
cmp.list.get_selected_item_idx()

cmp.list.on_show(function(ctx, items) end)
cmp.list.on_hide(function(ctx) end)
cmp.list.on_update(function(ctx, items) end)
cmp.list.on_select(function(ctx, item, idx) end)
cmp.list.on_accept(function(ctx, item) end)

---- Menu ----
cmp.menu.config({ ..., docs = { ... } }, filter?)
cmp.menu.enable(enable?, filter?) -- enabled by default
cmp.menu.is_enabled(filter?)

cmp.menu.is_visible()
cmp.menu.get_win()

cmp.menu.on_show(function(ctx) end)
cmp.menu.on_hide(function(ctx) end)

-- Menu Docs --
cmp.menu.docs.show()
cmp.menu.docs.hide()
cmp.menu.docs.scroll_up(count)
cmp.menu.docs.scroll_down(count)

cmp.menu.docs.is_visible()
cmp.menu.docs.get_win()

cmp.menu.docs.on_show(function(ctx) end)
cmp.menu.docs.on_hide(function(ctx) end)

---- Ghost text ----
cmp.ghost_text.enable(enable?, filter?)
cmp.ghost_text.is_enabled(filter?)

cmp.ghost_text.is_visible()
cmp.ghost_text.get_extmark_id()

cmp.ghost_text.on_show(function(ctx) end)
cmp.ghost_text.on_hide(function(ctx) end)

--- LSPs ---
-- sources system is no more, LSPs only, with compat layer for existing sources
cmp.lsp.config(client, options, filter?)
cmp.lsp.config('*', { ... }) -- global
cmp.lsp.config('lua_ls', { min_keyword_length = 2 })
cmp.lsp.config('buffer', { fallback_for = { "*", "!snippets", "!path" } })

-- default configs built-in for some LSPs, for example
cmp.lsp.config('ts_ls', { blocked_trigger_characters = { ' ', '\t', '\n' } })
cmp.lsp.config('emmet', { blocked_trigger_characters = function(char) return not char:match('[A-z]') end })
cmp.lsp.config('rust_analyzer', { bonuses = { frecency = false, proximity = false } })

-- all LSPs are enabled by default, except built-in "buffer", "snippets", "path"
cmp.lsp.enable('buffer', enable?, filter?)
cmp.lsp.enable({ 'buffer', 'path' }, enable?, filter?)
cmp.lsp.is_enabled('buffer', filter?)

--- Snippets ---
-- drop support for pulling snippets from luasnip/mini.snippets. encourage them to support in-process LSPs
-- as a result, this only affects how snippets are expanded/navigated
cmp.snippet.preset('luasnip', filter?) -- use a preset
cmp.snippet.config({ ... }, filter?) -- or define yourself

cmp.snippet.active(filter?)
cmp.snippet.jump(direction)

cmp.snippet.registry.add({ ... })
cmp.snippet.registry.remove({ ... })
cmp.snippet.registry.load({ ...paths }) -- vim.Task
cmp.snippet.registry.load_friendly_snippets()
cmp.snippet.registry.reload() -- vim.Task (reloads from .load() paths only)
cmp.snippet.registry.clear()

--- Signature ---
cmp.signature.config({
  docs = false,
  direction_priority = { 'n', 's' },
  window = { ... }
}, filter?)
cmp.signature.enable(enable?, filter?) -- enabled by default
cmp.signature.is_enabled(filter?)

cmp.signature.show() -- vim.Task
cmp.signature.hide()
cmp.signature.scroll_up(count)
cmp.signature.scroll_down(count)

cmp.signature.get_signatures()
cmp.signature.is_visible()
cmp.signature.get_win()

cmp.signature.on_show(function(ctx, signatures) end)
cmp.signature.on_hide(function(ctx) end)
