# Blink Completion (blink.cmp)

> [!IMPORTANT]
> This plugin is *beta* quality. Expect breaking changes and many bugs

**blink.cmp** is a completion plugin with support for LSPs and external sources that updates on every keystroke with minimal overhead (0.5-4ms async). It use a [custom SIMD fuzzy searcher](https://github.com/saghen/frizbee) to easily handle >20k items. It provides extensibility via hooks into the trigger, sources and rendering pipeline. Plenty of work has been put into making each stage of the pipeline as intelligent as possible, such as frecency and proximity bonus on fuzzy matching, and this work is on-going.

<video controls autoplay muted src="https://github.com/user-attachments/assets/9849e57a-3c2c-49a8-959c-dbb7fef78c80"></video>

## Features

- Works out of the box with no additional configuration
- Updates on every keystroke (0.5-4ms async, single core)
- [Typo resistant fuzzy](https://github.com/saghen/frizbee) with frecency and proximity bonus
- Extensive LSP support ([tracker](./development/lsp-tracker.md))
- Native `vim.snippet` support (including `friendly-snippets`)
- External sources support ([compatibility layer for `nvim-cmp` sources](https://github.com/Saghen/blink.compat))
- Auto-bracket support based on semantic tokens
- Signature help (experimental, opt-in)

## Special Thanks

- [@hrsh7th](https://github.com/hrsh7th/) nvim-cmp used as inspiration and cmp-path/cmp-cmdline implementations modified for path/cmdline sources
- [@garymjr](https://github.com/garymjr) nvim-snippets implementation modified for snippets source
- [@redxtech](https://github.com/redxtech) Help with design and testing
- [@aaditya-sahay](https://github.com/aaditya-sahay) Help with rust, design and testing

### Contributors

- [@stefanboca](https://github.com/stefanboca) Author of [blink.compat](https://github.com/saghen/blink.compat)
- [@lopi-py](https://github.com/lopi-py) Contributes to the windowing code
- [@scottmckendry](https://github.com/scottmckendry) Contributes to the CI and prebuilt binaries
- [@balssh](https://github.com/Balssh) Manages nixpkg and nixvim

## Compared to nvim-cmp

- Avoids the complexity of nvim-cmp's configuration by providing sensible defaults
- Updates on every keystroke with 0.5-4ms of overhead, versus nvim-cmp's default debounce of 60ms with 2-50ms hitches from processing
  - Setting nvim-cmp's debounce to 0ms leads to visible stuttering. If you'd like to stick with nvim-cmp, try [yioneko's fork](https://github.com/yioneko/nvim-cmp) or the more recent [magazine.nvim](https://github.com/iguanacucumber/magazine.nvim)
- Boosts completion item score via frecency _and_ proximity bonus. nvim-cmp boosts score via proximity bonus and optionally by recency
- Typo-resistant fuzzy matching unlike nvim-cmp's fzf-style fuzzy matching
- Core sources (buffer, snippets, path, lsp) are built-in versus nvim-cmp's exclusively external sources
- Built-in auto bracket and signature help support

### Planned missing features

- Significantly more testing and documentation
