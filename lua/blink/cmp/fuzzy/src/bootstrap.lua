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
