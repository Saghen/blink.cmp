local config = require('blink.cmp.config').completion.accept
local text_edit_lib = require('blink.cmp.lsp.text_edit')

--- @param ctx blink.cmp.Context
--- @param item blink.cmp.CompletionItem
local function apply_item(ctx, item)
  item = vim.deepcopy(item)

  -- Get additional text edits, converted to utf-8
  local all_text_edits = vim.tbl_map(
    function(text_edit) return text_edit_lib.to_utf_8(text_edit, text_edit_lib.offset_encoding_from_item(item)) end,
    vim.deepcopy(item.additionalTextEdits or {})
  )

  -- Create an undo point, if it's not a snippet, since the snippet engine handles undo
  if
    ctx.mode == 'default'
    and require('blink.cmp.config').completion.accept.create_undo_point
    and item.insertTextFormat ~= vim.lsp.protocol.InsertTextFormat.Snippet
  then
    -- setting the undolevels forces neovim to create an undo point
    vim.o.undolevels = vim.o.undolevels
  end

  -- Snippet
  if item.insertTextFormat == vim.lsp.protocol.InsertTextFormat.Snippet then
    assert(ctx.mode == 'default', 'Snippets are only supported in default mode')

    -- We want to handle offset_encoding and the text edit api can do this for us
    -- so we empty the newText and apply
    local temp_text_edit = vim.deepcopy(item.textEdit)
    temp_text_edit.newText = ''
    text_edit_lib.apply(temp_text_edit, all_text_edits)

    -- Expand the snippet
    require('blink.cmp.config').snippets.expand(item.textEdit.newText)

  -- OR Normal: Apply the text edit and move the cursor
  else
    local new_cursor = text_edit_lib.get_apply_end_position(item.textEdit, all_text_edits)
    new_cursor[2] = new_cursor[2]

    text_edit_lib.apply(item.textEdit, all_text_edits)
    ctx.set_cursor(new_cursor)
  end

  -- Notify the rust module that the item was accessed
  require('blink.cmp.fuzzy').access(item)
end

--- Applies a completion item to the current buffer
--- @param ctx blink.cmp.Context
--- @param item blink.cmp.CompletionItem
--- @param callback fun()
local function accept(ctx, item, callback)
  local sources = require('blink.cmp.sources.lib')
  require('blink.cmp.completion.trigger').hide()

  -- Start the resolve immediately since text changes can invalidate the item
  -- with some LSPs (e.g. rust-analyzer) causing them to return the item as-is
  -- without e.g. auto-imports
  sources
    .resolve(ctx, item)
    -- Some LSPs may take a long time to resolve the item, so we timeout
    :timeout(config.resolve_timeout_ms)
    -- and use the item as-is
    :catch(function() return item end)
    :map(function(resolved_item)
      -- Updates the text edit based on the cursor position and converts it to utf-8
      resolved_item = vim.deepcopy(resolved_item)
      resolved_item.textEdit = text_edit_lib.get_from_item(resolved_item)

      return apply_item(ctx, resolved_item)
    end)
    :map(function()
      require('blink.cmp.completion.trigger').show_if_on_trigger_character({ is_accept = true })
      require('blink.cmp.signature.trigger').show_if_on_trigger_character()
      callback()
    end)
    :catch(function(err) vim.notify(err, vim.log.levels.ERROR, { title = 'blink.cmp' }) end)
end

return accept
