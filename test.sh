#!/usr/bin/env bash

bash -c "mkdir -p .luarocks"
luarocks make --tree=.luarocks --deps-mode=all
eval "$(luarocks --tree=.luarocks path --append)"
luarocks test
