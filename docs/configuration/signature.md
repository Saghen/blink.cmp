---
title: Signature
---
# Signature <Badge type="info"><a href="./reference#signature">Go to default configuration</a></Badge>

> [!IMPORTANT]
> This feature is *experimental*, contributions welcome!

Blink supports signature help, automatically triggered when typing trigger characters, defined by the LSP, such as `(` for `lua`. The menu will be updated when pressing a retrigger character, such as `,`. Due to it being experimental, this feature is opt-in.

```lua
signature = { enabled = true }
```

<img src="https://github.com/user-attachments/assets/9ab576c8-2a04-465f-88c0-9c130fef146c" />

You may want to set `signature.window.show_documentation = false` to only show the signature, and not the documentation.
