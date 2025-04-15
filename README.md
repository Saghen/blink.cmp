# Blink Completion (blink.cmp)

**blink.cmp** is a completion plugin with support for LSPs and external sources that updates on every keystroke with minimal overhead (0.5-4ms async). It uses an [optional](https://cmp.saghen.dev/configuration/fuzzy.html#rust-vs-lua-implementation) custom [fuzzy matcher](https://github.com/saghen/frizbee) to easily handle 20k+ items. It provides extensibility via pluggable sources (LSP, snippets, etc), component based rendering and scripting for the configuration.

<https://github.com/user-attachments/assets/bd1e25dd-48b0-4d33-90f4-1468d822f2be>

## Features

- Works out of the box with no additional configuration
- Updates on every keystroke (0.5-4ms async, single core)
- [Typo resistant fuzzy](https://github.com/saghen/frizbee) with frecency and proximity bonus
- Extensive LSP support ([tracker](https://cmp.saghen.dev/development/lsp-tracker))
- [Snippet support](https://cmp.saghen.dev/configuration/snippets.html): native `vim.snippet` (including `friendly-snippets`), `LuaSnip` and `mini.snippets`
- External sources support ([community sources](https://cmp.saghen.dev/configuration/sources.html#community-sources) and [compatibility layer for `nvim-cmp` sources](https://github.com/saghen/blink.compat))
- [Auto-bracket support](https://cmp.saghen.dev/configuration/completion.html#auto-brackets) based on semantic tokens
- [Signature help](https://cmp.saghen.dev/configuration/signature.html) (experimental, opt-in)
- [Command line completion](https://cmp.saghen.dev/modes/cmdline.html)
- [Terminal completion](https://cmp.saghen.dev/modes/term) (0.11+ only! No source for shell completions exists yet, contributions welcome!)
- [Comparison with built-in completion](https://cmp.saghen.dev/#compared-to-built-in-completion)
- [Comparison with nvim-cmp](https://cmp.saghen.dev/#compared-to-nvim-cmp)

## Installation

Head over to the [documentation website](https://cmp.saghen.dev/installation) for installation instructions and configuration options.

## Special Thanks

- [@hrsh7th](https://github.com/hrsh7th/) nvim-cmp used as inspiration and cmp-path/cmp-cmdline implementations modified for path/cmdline sources
- [@garymjr](https://github.com/garymjr) nvim-snippets implementation modified for snippets source
- [@redxtech](https://github.com/redxtech) Help with design and testing
- [@aaditya-sahay](https://github.com/aaditya-sahay) Help with rust, design and testing

### Contributors

- [@stefanboca](https://github.com/stefanboca) Author of [blink.compat](https://github.com/saghen/blink.compat) and maintainer
- [@soifou](https://github.com/soifou) Maintainer
- [@lopi-py](https://github.com/lopi-py) Windowing code
- [@scottmckendry](https://github.com/scottmckendry) CI and prebuilt binaries
- [@balssh](https://github.com/Balssh) + [@konradmalik](https://github.com/konradmalik) Nix flake, nixpkg and nixvim
- [@abeldekat](https://github.com/abeldekat) mini.snippets source
- [@wurli](https://github.com/wurli) Terminal completions
- [@mikavilpas](https://github.com/mikavilpas) + [@xzbdmw](https://github.com/xzbdmw) Dot-repeat (`.`)
- [@FerretDetective](https://github.com/FerretDetective) `complete_func` source
- [@krovuxdev](https://github.com/krovuxdev) Community moderation and help
