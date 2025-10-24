--- @type table<string, table<string, blink.cmp.KeymapCommand[]>>
local full_presets = {
  default = {
    ['<C-space>'] = { 'show', 'show_documentation', 'hide_documentation' },
    ['<C-e>'] = { 'cancel', 'fallback' },
    ['<C-y>'] = { 'select_and_accept', 'fallback' },

    ['<Up>'] = { 'select_prev', 'fallback' },
    ['<Down>'] = { 'select_next', 'fallback' },
    ['<C-p>'] = { 'select_prev', 'fallback_to_mappings' },
    ['<C-n>'] = { 'select_next', 'fallback_to_mappings' },

    ['<C-b>'] = { 'scroll_documentation_up', 'fallback' },
    ['<C-f>'] = { 'scroll_documentation_down', 'fallback' },

    ['<Tab>'] = { 'snippet_forward', 'fallback' },
    ['<S-Tab>'] = { 'snippet_backward', 'fallback' },

    ['<C-k>'] = { 'show_signature', 'hide_signature', 'fallback' },
  },

  cmdline = {
    ['<Tab>'] = { 'show_and_insert_or_accept_single', 'select_next' },
    ['<S-Tab>'] = { 'show_and_insert_or_accept_single', 'select_prev' },

    ['<C-space>'] = { 'show', 'fallback' },

    ['<C-n>'] = { 'select_next', 'fallback' },
    ['<C-p>'] = { 'select_prev', 'fallback' },
    ['<Right>'] = { 'select_next', 'fallback' },
    ['<Left>'] = { 'select_prev', 'fallback' },

    ['<C-y>'] = { 'select_and_accept', 'fallback' },
    ['<C-e>'] = { 'cancel', 'fallback' },
    ['<End>'] = { 'hide', 'fallback' },
  },
}

--- Merged with the keymaps from the default preset
--- @type table<string, table<string, blink.cmp.KeymapCommand[]>>
local diff_presets = {
  ['super-tab'] = {
    ['<C-y>'] = {},
    ['<Tab>'] = {
      function(cmp)
        if cmp.snippet_active() then
          return cmp.accept()
        else
          return cmp.select_and_accept()
        end
      end,
      'snippet_forward',
      'fallback',
    },
  },

  enter = {
    ['<C-y>'] = {},
    ['<CR>'] = { 'accept', 'fallback' },
  },
}

--- @class blink.cmp.KeymapPresets
local presets = {}

--- Gets the preset keymap for the given preset name
--- @param name string
--- @return table<string, blink.cmp.KeymapCommand[]>
function presets.get(name)
  local full_preset = full_presets[name] or full_presets.default
  local diff_preset = diff_presets[name]

  if full_preset == nil and diff_preset == nil then error('Invalid blink.cmp keymap preset: ' .. name) end

  if diff_preset == nil then return full_preset end
  return presets.merge(full_preset, diff_preset)
end

--- @param existing_mappings table<string, blink.cmp.KeymapCommand[] | false>
--- @param new_mappings table<string, blink.cmp.KeymapCommand[] | false>
--- @return table<string, blink.cmp.KeymapCommand[]>
function presets.merge(existing_mappings, new_mappings)
  -- TODO: drop goto, filter out false values

  local merged_mappings = vim.deepcopy(existing_mappings)
  for new_key, new_mapping in pairs(new_mappings) do
    -- normalize the keys and replace, since naively merging would not handle <C-a> == <c-a>
    for existing_key, _ in pairs(existing_mappings) do
      if
        vim.api.nvim_replace_termcodes(existing_key, true, true, true)
        == vim.api.nvim_replace_termcodes(new_key, true, true, true)
      then
        merged_mappings[existing_key] = new_mapping
        goto continue
      end
    end

    -- key wasn't found, add it as per usual
    merged_mappings[new_key] = new_mapping

    ::continue::
  end
  return merged_mappings
end

return presets
