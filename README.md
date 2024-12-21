> [!WARNING]
> This plugin is _beta_ quality. Expect breaking changes and many bugs

# Blink Completion (blink.cmp)

**blink.cmp** is a completion plugin with support for LSPs and external sources that updates on every keystroke with minimal overhead (0.5-4ms async). It use a [custom SIMD fuzzy searcher](https://github.com/saghen/frizbee) to easily handle >20k items. It provides extensibility via hooks into the trigger, sources and rendering pipeline. Plenty of work has been put into making each stage of the pipeline as intelligent as possible, such as frecency and proximity bonus on fuzzy matching, and this work is on-going.

<https://github.com/user-attachments/assets/9849e57a-3c2c-49a8-959c-dbb7fef78c80>

## Features

- Works out of the box with no additional configuration
- Updates on every keystroke (0.5-4ms async, single core)
- [Typo resistant fuzzy](https://github.com/saghen/frizbee) with frecency and proximity bonus
- Extensive LSP support ([tracker](./docs/development/lsp-tracker.md))
- Native `vim.snippet` support (including `friendly-snippets`)
- External sources support ([compatibility layer for `nvim-cmp` sources](https://github.com/saghen/blink.compat))
- Auto-bracket support based on semantic tokens
- Signature help (experimental, opt-in)
- Command line completion
- [Comparison with nvim-cmp](#compared-to-nvim-cmp)

## Getting Started

Head over to the [documentation website](https://cmp.saghen.dev) for installation instructions and configuration options.

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
