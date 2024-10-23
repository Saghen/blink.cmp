--- @class blink.cmp.CompletionTriggerContext
--- @field kind number
--- @field character string | nil

--- @class blink.cmp.CompletionResponse
--- @field is_incomplete_forward boolean
--- @field is_incomplete_backward boolean
--- @field context blink.cmp.Context
--- @field items blink.cmp.CompletionItem[]

--- @class blink.cmp.Source
--- @field new fun(config: blink.cmp.SourceProviderConfig): blink.cmp.Source
--- @field get_trigger_characters (fun(self: blink.cmp.Source): string[]) | nil
--- @field get_completions fun(self: blink.cmp.Source, context: blink.cmp.Context, callback: fun(response: blink.cmp.CompletionResponse)): (fun(): nil) | nil
--- @field filter_completions (fun(self: blink.cmp.Source, response: blink.cmp.CompletionResponse): blink.cmp.CompletionItem[]) | nil
--- @field should_show_completions (fun(self: blink.cmp.Source, context: blink.cmp.Context, response: blink.cmp.CompletionResponse): boolean) | nil
--- @field resolve (fun(self: blink.cmp.Source, item: blink.cmp.CompletionItem, callback: fun(resolved_item: lsp.CompletionItem | nil)): ((fun(): nil) | nil)) | nil
--- @field get_signature_help_trigger_characters fun(self: blink.cmp.Source): string[]
--- @field get_signature_help fun(self: blink.cmp.Source, context: blink.cmp.SignatureHelpContext, callback: fun(signature_help: lsp.SignatureHelp | nil)): (fun(): nil) | nil
--- @field reload (fun(self: blink.cmp.Source): nil) | nil

--- @class blink.cmp.SourceOverride
--- @field get_trigger_characters fun(self: blink.cmp.Source): string[]
--- @field get_completions fun(self: blink.cmp.Source, context: blink.cmp.Context): blink.cmp.Task
--- @field filter_completions fun(self: blink.cmp.Source, response: blink.cmp.CompletionResponse): blink.cmp.CompletionItem[]
--- @field should_show_completions fun(self: blink.cmp.Source, context: blink.cmp.Context, response: blink.cmp.CompletionResponse): boolean
--- @field resolve fun(self: blink.cmp.Source, item: blink.cmp.CompletionItem): blink.cmp.Task
--- @field get_signature_help_trigger_characters fun(self: blink.cmp.Source): string[]
--- @field get_signature_help fun(self: blink.cmp.Source, context: blink.cmp.SignatureHelpContext): blink.cmp.Task
--- @field reload (fun(self: blink.cmp.Source): nil) | nil
