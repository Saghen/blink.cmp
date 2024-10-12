local git_ref = '$git_ref'
local modrev = '$modrev'
local specrev = '$specrev'

local repo_url = '$repo_url'

rockspec_format = '3.0'
package = '$package'
version = modrev ..'-'.. specrev

description = {
    summary = '$summary',
    detailed = $detailed_description,
    labels = $labels,
    homepage = '$homepage',
    $license
}

dependencies = $dependencies

build_dependencies = {
  'luarocks-build-rust-mlua',
}

test_dependencies = $test_dependencies

source = {
    url = repo_url .. '/archive/' .. git_ref .. '.zip',
    dir = '$repo_name-' .. '$archive_dir_suffix',
}

if modrev == 'scm' or modrev == 'dev' then
    source = {
        url = repo_url:gsub('https', 'git')
    }
end

build = {
    type = "rust-mlua",

    modules = {
        ["libblink_cmp_fuzzy"] = "blink_cmp_fuzzy",
    },

    install = {
        lua = {
            ["blink-cmp.init"] = "lua/blink-cmp.lua",
        },
    },

    copy_directories = $copy_directories,
}
