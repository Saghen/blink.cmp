# luarocks-build-rust-mlua

A [LuaRocks] build backend for Lua modules written in Rust using [mlua].

[LuaRocks]: http://luarocks.org
[mlua]: http://github.com/mlua-rs/mlua

# Example rockspec

```lua
package = "my_module"
version = "0.1.0-1"

source = {
    url = "git+https://github.com/username/my_module",
    tag = "0.1.0",
}

description = {
    summary = "Example Lua module in Rust",
    detailed = "...",
    homepage = "https://github.com/username/my_module",
    license = "MIT"
}

dependencies = {
    "lua >= 5.1",
    "luarocks-build-rust-mlua",
}

build = {
    type = "rust-mlua",

    modules = {
        -- Native library expected in `<target_path>/release/libmy_module.so` (linux; uses right name on macos/windows)
        "my_module",
        -- More complex case, native library expected in `<target_path>/release/libalt_name.so`
        ["my_module"] = "alt_name",
    },

    -- Optional: target_path if cargo "target" directory not in the module root
    target_path = "path/to/cargo/target/directory"

    -- Optional: if set to `false` pass `--no-default-features` to cargo
    default_features = false,

    -- Optional: pass additional features
    features = {"extra", "features"}
}
```
