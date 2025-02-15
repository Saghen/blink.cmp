# Fuzzy

Blink uses a SIMD fuzzy matcher called [frizbee](https://github.com/saghen/frizbee) which achieves ~6x the performance of fzf while ignoring typos. Check out the repo for more information!

## Installation

### Prebuilt binaries (default on a release tag)

By default, Blink will download a prebuilt binary from the latest release, when you're on a release tag (via `version = '*'` on `lazy.nvim` for example). If you're not on a release tag, you may force a specific version via `fuzzy.prebuilt_binaries.force_version`. See [the latest release](https://github.com/saghen/blink.cmp/releases/latest) for supported systems. See `prebuilt_binaries` section of the [reference configuration](./reference.md#prebuilt-binaries) for more options.

You may instead install the prebuilt binaries manually by downloading the appropriate binary from the [latest release](https://github.com/saghen/blink.cmp/releases/latest) and placing it at `$data/lazy/blink.cmp/target/release/libblink_cmp_fuzzy.$ext`. Get the `$data` path via `:echo stdpath('data')`. Use `.so` for linux, `.dylib` for mac, and `.dll` for windows. If you're unsure whether you want `-musl` or `-gnu` for linux, you very likely want `-gnu`.

```sh
# Linux
~/.local/share/nvim/lazy/blink.cmp/target/release/libblink_cmp_fuzzy.so

# Mac
~/.local/share/nvim/lazy/blink.cmp/target/release/libblink_cmp_fuzzy.dylib

# Windows
~/Appdata/Local/nvim/lazy/blink.cmp/target/release/libblink_cmp_fuzzy.dll
```

### Build from source (recommended for `main`)

When on `main`, it's highly recommended to build from source via `cargo build --release` (via `build = '...'` on `lazy.nvim` for example). This requires a nightly rust toolchain, which will be automatically downloaded when using `rustup`.

## Configuration

See the [fuzzy section of the reference configuration](./reference.md#fuzzy)
