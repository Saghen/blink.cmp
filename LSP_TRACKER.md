# LSP Support Tracker

## Completion Items

- [x] `completionItem/resolve` <- Used to get information such as documentation which would be too expensive to include normally

### Client Capabilities

- [ ] `dynamicRegistration`
- [ ] `CompletionItem`
    - [x] `snippetSupport`
    - [ ] `commitCharacterSupport`
    - [x] `documentationFormat`
    - [x] `deprecatedSupport`
    - [ ] `preselectSupport`
    - [x] `tagSupport`
    - [ ] `insertReplaceSupport`
    - [x] `resolveSupport` <- Allows LSPs to resolve additional properties lazily, potentially improving latency
    - [x] `insertTextModeSupport`
    - [x] `labelDetailsSupport`
- [x] `completionItemKind`
- [x] `contextSupport`

### Server Capabilities

- [x] `triggerCharacters`
- [ ] `allCommitCharacters`
- [x] `resolveProvider`
- [x] `CompletionItem`
    - [x] `labelDetailsSupport`

### Request Params

- [x] `CompletionContext`
    - [x] `triggerKind`
    - [x] `triggerCharacter`

### List

- [x] `isIncomplete`
- [x] `itemDefaults`
    - [x] `commitCharacters`
    - [ ] `editRange`
    - [x] `insertTextFormat`
    - [x] `insertTextMode`
    - [x] `data`
- [x] `items`

### Item

- [x] `label`
- [x] `labelDetails`
- [x] `kind`
- [x] `tags`
- [x] `detail`
- [x] `documentation` <- both string and markup content
- [x] `deprecated`
- [ ] `preselect`
- [ ] `sortText`
- [x] `filterText`
- [x] `insertText`
- [x] `insertTextFormat` <- regular or snippet
- [ ] `insertTextMode` <- asIs only, not sure we'll support adjustIndentation
- [x] `textEdit`
- [x] `textEditText`
- [x] `additionalTextEdits` <- known issue where applying the main text edit will cause this to be wrong if the additional text edit comes after since the indices will be offset
- [ ] `commitCharacters`
- [ ] `command`
- [x] `data` <- Don't think there's anything special to do here
