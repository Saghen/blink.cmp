# Introduction

**blink.cmp** is a completion plugin with support for LSPs, cmdline, signature help and snippets. It uses an [optional](https://cmp.saghen.dev/configuration/fuzzy.html#rust-vs-lua-implementation) custom [fuzzy matcher](https://github.com/saghen/frizbee) for typo resistance. It provides extensibility via pluggable sources (LSP, buffer, snippets, etc), component based rendering and scripting for the configuration.

<video controls autoplay muted src="https://github.com/user-attachments/assets/bd1e25dd-48b0-4d33-90f4-1468d822f2be"></video>

## Features

- Works out of the box with no additional configuration
- Updates on every keystroke (0.5-4ms async, single core)
- [Typo resistant fuzzy](https://github.com/saghen/frizbee) with frecency and proximity bonus
- Extensive LSP support ([tracker](/development/lsp-tracker))
- [Snippet support](/configuration/snippets): native `vim.snippet` (including `friendly-snippets`), `LuaSnip` and `mini.snippets`
- External sources support ([community sources](/configuration/sources#community-sources) and [compatibility layer for `nvim-cmp` sources](https://github.com/saghen/blink.compat))
- [Auto-bracket support](/configuration/completion#auto-brackets) based on semantic tokens
- [Signature help](/configuration/signature) (experimental, opt-in)
- [Command line completion](/modes/cmdline)
- [Terminal completion](/modes/term) (0.11+ only! No source for shell completions exists yet, contributions welcome!)

## Compared to built-in completion

- Typo resistant fuzzy matching
  - [Smarter scoring](https://github.com/saghen/frizbee#algorithm)
  - Proximity + frecency score bonuses
- Prefetching to minimize LSP latency
- Support for [external non-LSP sources](/configuration/sources.html#community-sources) (snippets, path, buffer, git, ripgrep, ...)
- [Ghost text](/configuration/completion.html#ghost-text)
- [Automatic signature help](/configuration/signature.html)
- [Auto-bracket support](/configuration/completion.html#auto-brackets) based on semantic tokens

## Compared to nvim-cmp

- Avoids the complexity of nvim-cmp's configuration by providing sensible defaults
- Updates on every keystroke with 0.5-4ms of overhead, versus nvim-cmp's default debounce of 60ms with 2-50ms hitches from processing
  - You may try [magazine.nvim](https://github.com/iguanacucumber/magazine.nvim) which includes many performance patches, some of which have been merged into nvim-cmp
- Boosts completion item score via frecency _and_ proximity bonus. nvim-cmp boosts score via proximity bonus and optionally by recency
- Typo-resistant fuzzy matching unlike nvim-cmp's fzf-style fuzzy matching
- Core sources (buffer, snippets, path, lsp) are built-in versus nvim-cmp's exclusively external sources
- Built-in auto bracket and signature help support
- Prefetching to minimize LSP latency

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
- [@soifou](https://github.com/soifou)
- [@FerretDetective](https://github.com/FerretDetective) `complete_func` source
- [@krovuxdev](https://github.com/krovuxdev) Community moderation and help
