#!/usr/bin/env bash
set -e

cd "$(dirname $(realpath $0))"
export LD_LIBRARY_PATH="$(pwd)/target/release"
export RUST_LUA_FFI_TYPE_PREFIX=blink_fuzzy
luajit "$(pwd)/src/bootstrap.lua" blink_fuzzy > "$(pwd)/init.lua"

sed -i "s/ffi\.load.'blink-fuzzy'./ffi.load(debug.getinfo(1).source:match('@?(.*\/)') .. 'target\/release\/libblink_fuzzy.so\')/" "$(pwd)/init.lua"
