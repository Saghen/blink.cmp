# LSP Support Tracker

## Completion Items

- [x] `completionItem/resolve` <- Used to get information such as documentation which would be too expensive to include normally

### Client Capabilities

- [ ] `dynamicRegistration`
- [ ] `CompletionItem`
    - [x] `snippetSupport` <- Are we advertising this?
    - [ ] `commitCharacterSupport`
    - [x] `documentationFormat` <- Are we advertising this?
    - [x] `deprecatedSupport` <- Are we advertising this?
    - [ ] `preselectSupport`
    - [x] `tagSupport` <- Are we advertising this?
    - [ ] `insertReplaceSupport`
    - [ ] `resolveSupport` <- Allows LSPs to resolve additional properties lazily, potentially improving latency
    - [ ] `insertTextModeSupport`
    - [ ] `labelDetailsSupport`
- [ ] `completionItemKind` <- Seems like we might not need to support this?
- [x] `contextSupport` <- Are we advertising this?
- [ ] `CompletionList`
    - [ ] `itemDefaults`

### Server Capabilities

- [x] `triggerCharacters`
- [ ] `allCommitCharacters`
- [ ] `resolveProvider` <- we always assume it can
- [ ] `CompletionItem`
    - [ ] `labelDetailsSupport`

### Request Params

- [x] `CompletionContext`
    - [x] `triggerKind`
    - [x] `triggerCharacter`

### List

- [x] `isIncomplete`
- [ ] `itemDefaults`
    - [ ] `commitCharacters`
    - [ ] `editRange`
    - [ ] `insertTextFormat`
    - [ ] `insertTextMode`
    - [ ] `data`
- [x] `items`

### Item

- [x] `label`
- [ ] `labelDetails`
- [x] `kind`
- [x] `tags`
- [x] `detail`
- [x] `documentation` <- both string and markup content
- [x] `deprecated`
- [ ] `preselect`
- [ ] `sortText`
- [ ] `filterText`
- [x] `insertText`
- [x] `insertTextFormat` <- regular or snippet
- [ ] `insertTextMode`
- [ ] `textEdit` <- we support `TextEdit` (typical) but not the rare `InsertReplaceEdit`
- [ ] `textEditText` <- add support when supporting defaults
- [x] `additionalTextEdits` <- known issue where applying the main text edit will cause this to be wrong if the additional text edit comes after since the indices will be offset
- [ ] `commitCharacters`
- [ ] `command`
- [x] `data` <- Don't think there's anything special to do here
