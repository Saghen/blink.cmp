local core = {}

core.view = {}
function core.view.visible() return require('blink.cmp.windows.autocomplete').win:is_open() end

return core
