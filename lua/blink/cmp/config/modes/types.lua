--- @class blink.cmp.ModeConfig
--- @field enabled? boolean
--- @field keymap? blink.cmp.KeymapConfig
--- @field completion? blink.cmp.ModeCompletionConfig

--- @class blink.cmp.ModeCompletionConfig
--- @field trigger? blink.cmp.ModeCompletionTriggerConfig
--- @field menu? blink.cmp.ModeCompletionMenuConfig

--- @class blink.cmp.ModeCompletionTriggerConfig
--- @field show_on_blocked_trigger_characters? string[] | (fun(): string[]) LSPs can indicate when to show the completion window via trigger characters. However, some LSPs (i.e. tsserver) return characters that would essentially always show the window. We block these by default.
--- @field show_on_x_blocked_trigger_characters? string[] | (fun(): string[]) List of trigger characters (on top of `show_on_blocked_trigger_characters`) that won't trigger the completion window when the cursor comes after a trigger character when entering insert mode/accepting an item

--- @class blink.cmp.ModeCompletionMenuConfig
--- @field auto_show? boolean | fun(ctx: blink.cmp.Context, items: blink.cmp.CompletionItem[]): boolean Whether to automatically show the window when new completion items are available
--- @field draw? blink.cmp.ModeDraw Controls how the completion items are rendered on the popup window

--- @class blink.cmp.ModeDraw
--- @field columns? blink.cmp.DrawColumnDefinition[] | fun(context: blink.cmp.Context): blink.cmp.DrawColumnDefinition[] Components to render, grouped by column
