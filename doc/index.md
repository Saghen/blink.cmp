# Introduction

::: warning
This plugin is *beta* quality. Expect breaking changes and many bugs
:::

**blink.cmp** is a completion plugin with support for LSPs and external sources that updates on every keystroke with minimal overhead (0.5-4ms async). It use a [custom fuzzy matcher](https://github.com/saghen/frizbee) to easily handle 20k+ items. It provides extensibility via pluggable sources (LSP, snippets, etc), component based rendering and scripting for the configuration.

<video controls autoplay muted src="https://github.com/user-attachments/assets/9849e57a-3c2c-49a8-959c-dbb7fef78c80"></video>

## Features

- Works out of the box with no additional configuration
- Updates on every keystroke (0.5-4ms async, single core)
- [Typo resistant fuzzy](https://github.com/saghen/frizbee) with frecency and proximity bonus
- Extensive LSP support ([tracker](/development/lsp-tracker.md))
- [Snippet support](/configuration/snippets.html): native `vim.snippet` (including `friendly-snippets`), `LuaSnip` and `mini.snippets`
- External sources support ([community sources](/configuration/sources.html#community-sources) and [compatibility layer for `nvim-cmp` sources](https://github.com/saghen/blink.compat))
- Auto-bracket support based on semantic tokens
- Signature help (experimental, opt-in)
- Command line completion
- Terminal completion (Nightly only! No source for shell completions exists yet, contributions welcome!)
- [Comparison with nvim-cmp](https://cmp.saghen.dev/#compared-to-nvim-cmp)

## Special Thanks

- [@hrsh7th](https://github.com/hrsh7th/) nvim-cmp used as inspiration and cmp-path/cmp-cmdline implementations modified for path/cmdline sources
- [@garymjr](https://github.com/garymjr) nvim-snippets implementation modified for snippets source
- [@redxtech](https://github.com/redxtech) Help with design and testing
- [@aaditya-sahay](https://github.com/aaditya-sahay) Help with rust, design and testing

### Contributors

- [@stefanboca](https://github.com/stefanboca) Author of [blink.compat](https://github.com/saghen/blink.compat)
- [@lopi-py](https://github.com/lopi-py) Windowing code
- [@scottmckendry](https://github.com/scottmckendry) CI and prebuilt binaries
- [@balssh](https://github.com/Balssh) + [@konradmalik](https://github.com/konradmalik) Nix flake, nixpkg and nixvim
- [@abeldekat](https://github.com/abeldekat) mini.snippets source
- [@wurli](https://github.com/wurli) Terminal completions
- [@mikavilpas](https://github.com/mikavilpas) + [@xzbdmw](https://github.com/xzbdmw) Dot-repeat (`.`)

## Compared to nvim-cmp

- Avoids the complexity of nvim-cmp's configuration by providing sensible defaults
- Updates on every keystroke with 0.5-4ms of overhead, versus nvim-cmp's default debounce of 60ms with 2-50ms hitches from processing
  - You may try [magazine.nvim](https://github.com/iguanacucumber/magazine.nvim) which includes many performance patches, some of which have been merged into nvim-cmp
- Boosts completion item score via frecency _and_ proximity bonus. nvim-cmp boosts score via proximity bonus and optionally by recency
- Typo-resistant fuzzy matching unlike nvim-cmp's fzf-style fuzzy matching
- Core sources (buffer, snippets, path, lsp) are built-in versus nvim-cmp's exclusively external sources
- Built-in auto bracket and signature help support
- Prefetching to minimize LSP latency

### Planned missing features

- Significantly more testing
- No breaking changes
