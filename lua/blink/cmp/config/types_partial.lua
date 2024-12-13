--- @class (exact) blink.cmp.Config : blink.cmp.ConfigStrict
--- @field enabled? fun(): boolean
--- @field keymap? blink.cmp.KeymapConfig
--- @field completion? blink.cmp.CompletionConfigPartial
--- @field fuzzy? blink.cmp.FuzzyConfigPartial
--- @field sources? blink.cmp.SourceConfigPartial
--- @field signature? blink.cmp.SignatureConfigPartial
--- @field snippets? blink.cmp.SnippetsConfigPartial
--- @field appearance? blink.cmp.AppearanceConfigPartial

--- @class (exact) blink.cmp.CompletionConfigPartial : blink.cmp.CompletionConfig
--- @field keyword? blink.cmp.CompletionKeywordConfigPartial
--- @field trigger? blink.cmp.CompletionTriggerConfigPartial
--- @field list? blink.cmp.CompletionListConfigPartial
--- @field accept? blink.cmp.CompletionAcceptConfigPartial
--- @field menu? blink.cmp.CompletionMenuConfigPartial
--- @field documentation? blink.cmp.CompletionDocumentationConfigPartial
--- @field ghost_text? blink.cmp.CompletionGhostTextConfigPartial

--- @class (exact) blink.cmp.CompletionKeywordConfigPartial : blink.cmp.CompletionKeywordConfig
--- 'prefix' will fuzzy match on the text before the cursor
--- 'full' will fuzzy match on the text before *and* after the cursor
--- example: 'foo_|_bar' will match 'foo_' for 'prefix' and 'foo__bar' for 'full'
--- @field range? blink.cmp.CompletionKeywordRange
--- @field regex? string Regex used to get the text when fuzzy matching
--- @field exclude_from_prefix_regex? string After matching with regex, any characters matching this regex at the prefix will be excluded

--- @class (exact) blink.cmp.CompletionTriggerConfigPartial : blink.cmp.CompletionTriggerConfig
--- @field prefetch_on_insert? boolean When true, will prefetch the completion items when entering insert mode. WARN: buggy, not recommended unless you'd like to help develop prefetching
--- @field show_in_snippet? boolean When false, will not show the completion window when in a snippet
--- @field show_on_keyword? boolean When true, will show the completion window after typing a character that matches the `keyword.regex`
--- @field show_on_trigger_character? boolean When true, will show the completion window after typing a trigger character
--- @field show_on_blocked_trigger_characters? string[] | (fun(): string[]) LSPs can indicate when to show the completion window via trigger characters. However, some LSPs (i.e. tsserver) return characters that would essentially always show the window. We block these by default.
--- @field show_on_accept_on_trigger_character? boolean When both this and show_on_trigger_character are true, will show the completion window when the cursor comes after a trigger character after accepting an item
--- @field show_on_insert_on_trigger_character? boolean When both this and show_on_trigger_character are true, will show the completion window when the cursor comes after a trigger character when entering insert mode
--- @field show_on_x_blocked_trigger_characters? string[] | (fun(): string[]) List of trigger characters (on top of `show_on_blocked_trigger_characters`) that won't trigger the completion window when the cursor comes after a trigger character when entering insert mode/accepting an item

--- @class (exact) blink.cmp.CompletionListConfigPartial : blink.cmp.CompletionListConfig
--- @field max_items? number Maximum number of items to display
--- @field selection? blink.cmp.CompletionListSelection Controls if completion items will be selected automatically, and whether selection automatically inserts
--- @field cycle? blink.cmp.CompletionListCycleConfigPartial

--- @class (exact) blink.cmp.CompletionListCycleConfigPartial : blink.cmp.CompletionListCycleConfig
--- @field from_bottom? boolean When `true`, calling `select_next` at the *bottom* of the completion list will select the *first* completion item.
--- @field from_top? boolean When `true`, calling `select_prev` at the *top* of the completion list will select the *last* completion item.

--- @class (exact) blink.cmp.CompletionAcceptConfigPartial : blink.cmp.CompletionAcceptConfig
--- @field create_undo_point? boolean Create an undo point when accepting a completion item
--- @field auto_brackets? blink.cmp.AutoBracketsConfigPartial

--- @class (exact) blink.cmp.AutoBracketsConfigPartial : blink.cmp.AutoBracketsConfig
--- @field enabled? boolean Whether to auto-insert brackets for functions
--- @field default_brackets? string[] Default brackets to use for unknown languages
--- @field override_brackets_for_filetypes? table<string, string[] | fun(item: blink.cmp.CompletionItem): string[]>
--- @field force_allow_filetypes? string[] Overrides the default blocked filetypes
--- @field blocked_filetypes? string[]
--- @field kind_resolution? blink.cmp.AutoBracketResolutionConfigPartial Synchronously use the kind of the item to determine if brackets should be added
--- @field semantic_token_resolution? blink.cmp.AutoBracketSemanticTokenResolutionConfigPartial Asynchronously use semantic token to determine if brackets should be added

--- @class (exact) blink.cmp.AutoBracketResolutionConfigPartial : blink.cmp.AutoBracketResolutionConfig
--- @field enabled? boolean
--- @field blocked_filetypes? string[]

--- @class (exact) blink.cmp.AutoBracketSemanticTokenResolutionConfigPartial : blink.cmp.AutoBracketSemanticTokenResolutionConfig
--- @field enabled? boolean
--- @field blocked_filetypes? string[]
--- @field timeout_ms? number How long to wait for semantic tokens to return before assuming no brackets should be added

--- @class (exact) blink.cmp.CompletionMenuConfigPartial : blink.cmp.CompletionMenuConfig
--- @field enabled? boolean
--- @field min_width? number
--- @field max_height? number
--- @field border? blink.cmp.WindowBorder
--- @field winblend? number
--- @field winhighlight? string
--- @field scrolloff? number Keep the cursor X lines away from the top/bottom of the window
--- @field scrollbar? boolean Note that the gutter will be disabled when border ~= 'none'
--- @field direction_priority? ("n" | "s")[] Which directions to show the window, falling back to the next direction when there's not enough space
--- @field order? blink.cmp.CompletionMenuOrderConfigPartial TODO: implement
--- @field auto_show? boolean Whether to automatically show the window when new completion items are available
--- @field cmdline_position? fun(): number[] Screen coordinates (0-indexed) of the command line
--- @field draw? blink.cmp.Draw Controls how the completion items are rendered on the popup window

--- @class (exact) blink.cmp.CompletionMenuOrderConfigPartial : blink.cmp.CompletionMenuOrderConfig
--- @field n? 'top_down' | 'bottom_up'
--- @field s? 'top_down' | 'bottom_up'

--- @class (exact) blink.cmp.CompletionDocumentationConfigPartial : blink.cmp.CompletionDocumentationConfig
--- @field auto_show? boolean Controls whether the documentation window will automatically show when selecting a completion item
--- @field auto_show_delay_ms? number Delay before showing the documentation window
--- @field update_delay_ms? number Delay before updating the documentation window when selecting a new item, while an existing item is still visible
--- @field treesitter_highlighting? boolean Whether to use treesitter highlighting, disable if you run into performance issues
--- @field window? blink.cmp.CompletionDocumentationWindowConfigPartial

--- @class (exact) blink.cmp.CompletionDocumentationWindowConfigPartial : blink.cmp.CompletionDocumentationWindowConfig
--- @field min_width? number
--- @field max_width? number
--- @field max_height? number
--- @field desired_min_width? number
--- @field desired_min_height? number
--- @field border? blink.cmp.WindowBorder
--- @field winblend? number
--- @field winhighlight? string
--- @field scrollbar? boolean Note that the gutter will be disabled when border ~= 'none'
--- @field direction_priority? blink.cmp.CompletionDocumentationDirectionPriorityConfigPartial Which directions to show the window, for each of the possible menu window directions, falling back to the next direction when there's not enough space

--- @class (exact) blink.cmp.CompletionDocumentationDirectionPriorityConfigPartial : blink.cmp.CompletionDocumentationDirectionPriorityConfig
--- @field menu_north? ("n" | "s" | "e" | "w")[]
--- @field menu_south? ("n" | "s" | "e" | "w")[]

--- @class (exact) blink.cmp.CompletionGhostTextConfigPartial : blink.cmp.CompletionGhostTextConfig
--- @field enabled? boolean

--- @class (exact) blink.cmp.FuzzyConfigPartial : blink.cmp.FuzzyConfig
--- @field use_typo_resistance? boolean When enabled, allows for a number of typos relative to the length of the query. Disabling this matches the behavior of fzf
--- @field use_frecency? boolean Tracks the most recently/frequently used items and boosts the score of the item
--- @field use_proximity? boolean Boosts the score of items matching nearby words
--- @field sorts? ("label" | "kind" | "score" | blink.cmp.SortFunction)[] Controls which sorts to use and in which order, these three are currently the only allowed options
--- @field prebuilt_binaries? blink.cmp.PrebuiltBinariesConfigPartial

--- @class (exact) blink.cmp.PrebuiltBinariesConfigPartial : blink.cmp.PrebuiltBinariesConfig
--- @field download? boolean Whenther or not to automatically download a prebuilt binary from github. If this is set to `false` you will need to manually build the fuzzy binary dependencies by running `cargo build --release`
--- @field force_version? string When downloading a prebuilt binary, force the downloader to resolve this version. If this is unset then the downloader will attempt to infer the version from the checked out git tag (if any). WARN: Beware that `main` may be incompatible with the version you select
--- @field force_system_triple? string When downloading a prebuilt binary, force the downloader to use this system triple. If this is unset then the downloader will attempt to infer the system triple from `jit.os` and `jit.arch`. Check the latest release for all available system triples. WARN: Beware that `main` may be incompatible with the version you select
--- @field extra_curl_args? string[] Extra arguments that will be passed to curl like { 'curl', ..extra_curl_args, ..built_in_args }

--- @class blink.cmp.SourceConfigPartial : blink.cmp.SourceConfig
--- Static list of providers to enable, or a function to dynamically enable/disable providers based on the context
---
--- Example dynamically picking providers based on the filetype and treesitter node:
--- ```lua
---   function(ctx)
---     local node = vim.treesitter.get_node()
---     if vim.bo.filetype == 'lua' then
---       return { 'lsp', 'path' }
---     elseif node and vim.tbl_contains({ 'comment', 'line_comment', 'block_comment' }), node:type())
---       return { 'buffer' }
---     else
---       return { 'lsp', 'path', 'snippets', 'buffer' }
---     end
---   end
--- ```
--- @field default? string[] | fun(): string[]
--- @field per_filetype? table<string, string[] | fun(): string[]>
--- @field cmdline? string[] | fun(): string[]
---
--- @field transform_items? fun(ctx: blink.cmp.Context, items: blink.cmp.CompletionItem[]): blink.cmp.CompletionItem[] Function to transform the items before they're returned
--- @field min_keyword_length? number | fun(ctx: blink.cmp.Context): number Minimum number of characters in the keyword to trigger
---
--- @field providers? table<string, blink.cmp.SourceProviderConfigPartial>

--- @class blink.cmp.SourceProviderConfigPartial : blink.cmp.SourceProviderConfig
--- @field name? string
--- @field module? string
--- @field enabled? boolean | fun(ctx?: blink.cmp.Context): boolean Whether or not to enable the provider
--- @field opts? table
--- @field async? boolean | fun(ctx: blink.cmp.Context): boolean Whether blink should wait for the source to return before showing the completions
--- @field timeout_ms? number | fun(ctx: blink.cmp.Context): number How long to wait for the provider to return before showing completions and treating it as asynchronous
--- @field transform_items? fun(ctx: blink.cmp.Context, items: blink.cmp.CompletionItem[]): blink.cmp.CompletionItem[] Function to transform the items before they're returned
--- @field should_show_items? boolean | fun(ctx: blink.cmp.Context, items: blink.cmp.CompletionItem[]): boolean Whether or not to show the items
--- @field max_items? number | fun(ctx: blink.cmp.Context, items: blink.cmp.CompletionItem[]): number Maximum number of items to display in the menu
--- @field min_keyword_length? number | fun(ctx: blink.cmp.Context): number Minimum number of characters in the keyword to trigger the provider
--- @field fallbacks? string[] | fun(ctx: blink.cmp.Context, enabled_sources: string[]): string[] If this provider returns 0 items, it will fallback to these providers
--- @field score_offset? number | fun(ctx: blink.cmp.Context, enabled_sources: string[]): number Boost/penalize the score of the items
--- @field deduplicate? blink.cmp.DeduplicateConfig TODO: implement
--- @field override? blink.cmp.SourceOverride Override the source's functions

--- @class (exact) blink.cmp.SignatureConfigPartial : blink.cmp.SignatureConfig
--- @field enabled? boolean
--- @field trigger? blink.cmp.SignatureTriggerConfigPartial
--- @field window? blink.cmp.SignatureWindowConfigPartial

--- @class (exact) blink.cmp.SignatureTriggerConfigPartial : blink.cmp.SignatureTriggerConfig
--- @field blocked_trigger_characters? string[]
--- @field blocked_retrigger_characters? string[]
--- @field show_on_insert_on_trigger_character? boolean When true, will show the signature help window when the cursor comes after a trigger character when entering insert mode

--- @class (exact) blink.cmp.SignatureWindowConfigPartial : blink.cmp.SignatureWindowConfig
--- @field min_width? number
--- @field max_width? number
--- @field max_height? number
--- @field border? blink.cmp.WindowBorder
--- @field winblend? number
--- @field winhighlight? string
--- @field scrollbar? boolean Note that the gutter will be disabled when border ~= 'none'
--- @field direction_priority? ("n" | "s")[] Which directions to show the window, falling back to the next direction when there's not enough space, or another window is in the way.
--- @field treesitter_highlighting? boolean Disable if you run into performance issues

--- @class (exact) blink.cmp.SnippetsConfigPartial : blink.cmp.SnippetsConfig
--- @field expand? fun(snippet: string) Function to use when expanding LSP provided snippets
--- @field active? fun(filter?: { direction?: number }): boolean Function to use when checking if a snippet is active
--- @field jump? fun(direction: number) Function to use when jumping between tab stops in a snippet, where direction can be negative or positive

--- @class (exact) blink.cmp.AppearanceConfigPartial : blink.cmp.AppearanceConfig
--- @field highlight_ns? number
--- @field use_nvim_cmp_as_default? boolean Sets the fallback highlight groups to nvim-cmp's highlight groups. Useful for when your theme doesn't support blink.cmp, will be removed in a future release.
--- @field nerd_font_variant? 'mono' | 'normal' Set to 'mono' for 'Nerd Font Mono' or 'normal' for 'Nerd Font'. Adjusts spacing to ensure icons are aligned
--- @field kind_icons? table<string, string>
