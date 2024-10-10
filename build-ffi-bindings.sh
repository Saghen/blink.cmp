#!/usr/bin/env bash
set -e
cd "$(dirname "$(realpath "$0")")"

# shellcheck disable=SC2155
export LD_LIBRARY_PATH="$(pwd)/target/release"
export RUST_LUA_FFI_TYPE_PREFIX=blink_cmp_fuzzy

cat <<EOF > "$(pwd)/lua/blink/cmp/fuzzy/bootstrap.lua"
local ffi = require("ffi")

ffi.cdef([[
    char *__lua_bootstrap();
    void __free_lua_bootstrap(char *);
]])
local rust = ffi.load(arg[1])

local bootstrap = rust.__lua_bootstrap()
if bootstrap == nil then
	error("lua_bootstrap failed")
end
ffi.gc(bootstrap, rust.__free_lua_bootstrap)
print(ffi.string(bootstrap))
EOF

luajit "$(pwd)/lua/blink/cmp/fuzzy/bootstrap.lua" blink_cmp_fuzzy > "$(pwd)/lua/blink/cmp/fuzzy/ffi.lua"
rm "$(pwd)/lua/blink/cmp/fuzzy/bootstrap.lua"

# hack: super scuffed way of getting the shared lib extension
# and rewriting the ffi.lua file to point to the correct target dir

echo "
local function get_shared_lib_extension()
    local os = jit.os:lower()
    if os == 'osx' or os == 'mac' then
        return '.dylib'
    elseif os == 'windows' then
        return '.dll'
    else
      return '.so'
    end
end

$(cat "$(pwd)/lua/blink/cmp/fuzzy/ffi.lua")
" > "$(pwd)/lua/blink/cmp/fuzzy/ffi.lua"

sed -i "s|ffi\.load('blink-cmp-fuzzy').|local ok, rust = pcall(function() return ffi.load(debug.getinfo(1).source:match('@?(.*/)') .. '../../../../target/release/libblink_cmp_fuzzy' .. get_shared_lib_extension()) end)\nif not ok then\n    rust = ffi.load(debug.getinfo(1).source:match('@?(.*/)') .. '../../../../target/release/blink_cmp_fuzzy' .. get_shared_lib_extension())\nend|" "$(pwd)/lua/blink/cmp/fuzzy/ffi.lua"
