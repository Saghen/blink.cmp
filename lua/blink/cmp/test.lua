vim.api.nvim_create_autocmd('InsertCharPre', {
  callback = function() 
	  vim.print(vim.v.char)
	  vim.print(string.byte(vim.v.char, 1)) 
  end,
})

vim.on_key(function(key)
  if key == 'e' then
    vim.api.nvim_buf_set_text(0, 0, 0, 0, 0, { 'WOOOO' })
  end
end)

