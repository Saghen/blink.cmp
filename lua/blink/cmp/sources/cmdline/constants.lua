-- spellchecker:off
return {
  help_commands = {
    help = true,
    hel = true,
    he = true,
    h = true,
  },
  completion_types = {
    buffer = { 'buffer', 'diff_buffer' },
    path = { 'dir', 'dir_in_path', 'file', 'file_in_path' },
  },
}
-- spellchecker:on
