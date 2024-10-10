--- @class blink.cmp.CompletionTriggerContext
--- @field kind number
--- @field character string | nil
---
--- @class blink.cmp.CompletionResponse
--- @field is_incomplete_forward boolean
--- @field is_incomplete_backward boolean
--- @field context blink.cmp.Context
--- @field items blink.cmp.CompletionItem[]
---
--- @class blink.cmp.Source
--- @field new fun(opts: table, name: string): blink.cmp.Source
--- @field get_trigger_characters (fun(self: blink.cmp.Source): string[]) | nil
--- @field get_completions fun(self: blink.cmp.Source, context: blink.cmp.Context, callback: fun(response: blink.cmp.CompletionResponse)): (fun(): nil) | nil
--- @field filter_completions (fun(self: blink.cmp.Source, response: blink.cmp.CompletionResponse): blink.cmp.CompletionItem[]) | nil
--- @field should_show_completions (fun(self: blink.cmp.Source, context: blink.cmp.Context, response: blink.cmp.CompletionResponse): boolean) | nil
--- @field resolve (fun(self: blink.cmp.Source, item: blink.cmp.CompletionItem, callback: fun(resolved_item: lsp.CompletionItem | nil)): ((fun(): nil) | nil)) | nil
