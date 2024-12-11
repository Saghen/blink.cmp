local text_edits_lib = require('blink.cmp.lib.text_edits')
local brackets_lib = require('blink.cmp.completion.brackets')

--- Applies a completion item to the current buffer
--- @param ctx blink.cmp.Context
--- @param item blink.cmp.CompletionItem
--- @param callback fun()
local function accept(ctx, item, callback)
  local sources = require('blink.cmp.sources.lib')
  require('blink.cmp.completion.trigger').hide()

  -- Start the resolve immediately since text changes can invalidate the item
  -- with some LSPs (i.e. rust-analyzer) causing them to return the item as-is
  -- without i.e. auto-imports
  sources
    .resolve(item)
    :map(function(resolved_item)
      -- Get additional text edits, converted to utf-8
      local all_text_edits =
        vim.deepcopy(resolved_item and resolved_item.additionalTextEdits or item.additionalTextEdits or {})
      all_text_edits = vim.tbl_map(
        function(text_edit) return text_edits_lib.to_utf_8(text_edit, text_edits_lib.offset_encoding_from_item(item)) end,
        all_text_edits
      )

      item = vim.deepcopy(item)
      -- TODO: it's not obvious that this is converting to utf-8
      item.textEdit = text_edits_lib.get_from_item(item)

      -- Create an undo point, if it's not a snippet, since the snippet engine should handle undo
      if
        ctx.mode == 'default'
        and item.insertTextFormat ~= vim.lsp.protocol.InsertTextFormat.Snippet
        and require('blink.cmp.config').completion.accept.create_undo_point
      then
        vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes('<C-g>u', true, true, true), 'n', true)
      end

      -- Add brackets to the text edit if needed
      local brackets_status, text_edit_with_brackets, offset = brackets_lib.add_brackets(ctx, vim.bo.filetype, item)
      item.textEdit = text_edit_with_brackets

      -- Snippet
      if item.insertTextFormat == vim.lsp.protocol.InsertTextFormat.Snippet then
        assert(ctx.mode == 'default', 'Snippets are only supported in default mode')

        -- We want to handle offset_encoding and the text edit api can do this for us
        -- so we empty the newText and apply
        local temp_text_edit = vim.deepcopy(item.textEdit)
        temp_text_edit.newText = ''
        table.insert(all_text_edits, temp_text_edit)
        text_edits_lib.apply(all_text_edits)

        -- Expand the snippet
        require('blink.cmp.config').snippets.expand(item.textEdit.newText)

      -- OR Normal: Apply the text edit and move the cursor
      else
        table.insert(all_text_edits, item.textEdit)
        text_edits_lib.apply(all_text_edits)
        -- TODO: should move the cursor only by the offset since text edit handles everything else?
        ctx.set_cursor({ ctx.get_cursor()[1], item.textEdit.range.start.character + #item.textEdit.newText + offset })
      end

      -- Let the source execute the item itself
      sources.execute(ctx, item):map(function()
        -- Check semantic tokens for brackets, if needed, and apply additional text edits
        if brackets_status == 'check_semantic_token' then
          -- TODO: since we apply the additional text edits after, auto imported functions will not
          -- get auto brackets. If we apply them before, we have to modify the textEdit to compensate
          brackets_lib.add_brackets_via_semantic_token(vim.bo.filetype, item, function()
            require('blink.cmp.completion.trigger').show_if_on_trigger_character({ is_accept = true })
            require('blink.cmp.signature.trigger').show_if_on_trigger_character()
            callback()
          end)
        else
          require('blink.cmp.completion.trigger').show_if_on_trigger_character({ is_accept = true })
          require('blink.cmp.signature.trigger').show_if_on_trigger_character()
          callback()
        end

        -- Notify the rust module that the item was accessed
        -- TODO: why is this so slow? (10ms)
        vim.schedule(function() require('blink.cmp.fuzzy').access(item) end)
      end)
    end)
    :catch(function(err) vim.notify(err, vim.log.levels.ERROR) end)
end

return accept
