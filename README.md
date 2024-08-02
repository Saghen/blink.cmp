# Blink Completion (blink.cmp)

**blink.cmp** provides a completion plugin with support for LSPs and external sources while updating on every keystroke with minimal overhead (0.5-4ms async). It achieves this by writing the fuzzy searching in SIMD to easily handle >20k items. It provides extensibility via hooks into the trigger, sources and rendering pipeline. Plenty of work has been put into making each stage of the pipeline as intelligent as possible, such as frecency and proximity bonus on fuzzy matching, and this work is on-going. `nvim-cmp` sources are supported out of the box but migration to the `blink.cmp` style source is highly encouraged.

## Features

- Simple hackable codebase
- Updates on every keystroke (0.5-4ms non-blocking, single core)
- Typo resistant fuzzy with frecncy and proximity bonus
- Extensive LSP support ([tracker](./LSP_TRACKER.md))
- Snippet support (including `friendly-snippets`)
- TODO: Cmdline support
- External sources support (including `nvim-cmp` compatibility layer)

## Installation

TODO: move the keymaps into the plugin?

`lazy.nvim`

```lua
--- @param mode string|string[] modes to map
--- @param lhs string lhs
--- @param rhs string rhs
local function map_blink_cmp(mode, lhs, rhs)
	return {
		lhs,
		function()
			local did_run = require('blink.cmp')[rhs]()
			if not did_run then
				return lhs
			end
		end,
		mode = mode,
		expr = true,
		noremap = true,
		silent = true,
		replace_keycodes = true,
	}
end


{
  'saghen/blink.nvim',
  -- todo: should handle lazy loading internally
  event = 'InsertEnter',
  dependencies = {
    {
      'garymjr/nvim-snippets',
      dependencies = { 'rafamadriz/friendly-snippets' },
      opts = { create_cmp_source = false, friendly_snippets = true },
    },
  },
  keys = {
    map_blink_cmp('i', '<C-space>', 'show'),
    map_blink_cmp('i', '<Tab>', 'accept'),
    map_blink_cmp('i', '<Up>', 'select_prev'),
    map_blink_cmp('i', '<Down>', 'select_next'),
    map_blink_cmp('i', '<C-k>', 'select_prev'),
    map_blink_cmp('i', '<C-j>', 'select_next'),
  },
  opts = {
    -- see lua/blink/cmp/config.lua for all options
    cmp = { enabled = true }
  }
}
```

## How it works

The plugin use a 4 stage pipeline: trigger -> sources -> fuzzy -> render

**Trigger:** Controls when to request completion items from the sources and provides a context downstream with the current query (i.e. `hello.wo|`, the query would be `wo`) and the treesitter object under the cursor (i.e. for intelligently enabling/disabling sources). It respects trigger characters passed by the LSP (or any other source) and includes it in the context for sending to the LSP.

**Sources:** Provides a common interface for and merges the results of completion, trigger character, resolution of additional information and cancellation. It also provides a compatibility layer to `nvim-cmp`'s sources. Many sources are builtin: `LSP`, `buffer`, `treesitter`, `path`, `snippets`

**Fuzzy:** Rust <-> Lua FFI which performs both filtering and sorting of the items

&nbsp;&nbsp;&nbsp;&nbsp;**Filtering:** The fuzzy matching uses smith-waterman, same as FZF, but implemented in SIMD for ~6x the performance of FZF (todo: add benchmarks). Due to the SIMD's performance, the prefiltering phase on FZF was dropped to allow for typos. Similar to fzy/fzf, additional points are given to prefix matches, characters with capitals (to promote camelCase/PascalCase first char matching) and matches after delimiters (to promote snake_case first char matching)

&nbsp;&nbsp;&nbsp;&nbsp;**Sorting:** Combines fuzzy matching score with frecency and proximity bonus. Each completion item may also include a `score_offset` which will be added to this score to demote certain sources. The `buffer` and `snippets` sources take advantage of this to avoid taking presedence over the LSP source. The paramaters here still need to be tuned and have been exposed, so please let me know if you find some magical parameters!

**Render:** Responsible for placing the autocomplete, documentation and function parameters windows. All of the rendering can be overriden following a syntax similar to incline.nvim. It uses the neovim window decoration provider to provide next to no overhead from highlighting. 

## Special Thanks

@redxtech Help with design, testing and being my biggest fan
@aadityasahay Help with rust and design
