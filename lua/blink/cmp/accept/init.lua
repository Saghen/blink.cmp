local text_edits_lib = require('blink.cmp.accept.text-edits')
local brackets_lib = require('blink.cmp.accept.brackets')

--- Applies a completion item to the current buffer
--- @param item blink.cmp.CompletionItem
local function accept(item)
  require('blink.cmp.trigger.completion').hide()

  -- start the resolve immediately since text changes can invalidate the item
  -- with some LSPs (i.e. rust-analyzer) causing them to return the item as-is
  -- without i.e. auto-imports
  require('blink.cmp.sources.lib')
    .resolve(item)
    :map(function(resolved_item)
      local all_text_edits =
        vim.deepcopy(resolved_item and resolved_item.additionalTextEdits or item.additionalTextEdits or {})

      -- create an undo point
      if require('blink.cmp.config').accept.create_undo_point then
        vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes('<C-g>u', true, true, true), 'n', true)
      end

      item = vim.deepcopy(item)
      item.textEdit = text_edits_lib.get_from_item(item)

      -- Add brackets to the text edit if needed
      local brackets_status, text_edit_with_brackets, offset = brackets_lib.add_brackets(vim.bo.filetype, item)
      item.textEdit = text_edit_with_brackets

      -- Snippet
      if item.insertTextFormat == vim.lsp.protocol.InsertTextFormat.Snippet then
        -- We want to handle offset_encoding and the text edit api can do this for us
        -- so we empty the newText and apply
        local temp_text_edit = vim.deepcopy(item.textEdit)
        temp_text_edit.newText = ''
        table.insert(all_text_edits, temp_text_edit)
        text_edits_lib.apply_text_edits(item.client_id, all_text_edits)

        -- Expand the snippet
        vim.snippet.expand(item.textEdit.newText)

      -- OR Normal: Apply the text edit and move the cursor
      else
        table.insert(all_text_edits, item.textEdit)
        text_edits_lib.apply_text_edits(item.client_id, all_text_edits)
        -- TODO: should move the cursor only by the offset since text edit handles everything else?
        vim.api.nvim_win_set_cursor(0, {
          vim.api.nvim_win_get_cursor(0)[1],
          item.textEdit.range.start.character + #item.textEdit.newText + offset,
        })
      end

      -- Check semantic tokens for brackets, if needed, and apply additional text edits
      if brackets_status == 'check_semantic_token' then
        -- TODO: since we apply the additional text edits after, auto imported functions will not
        -- get auto brackets. If we apply them before, we have to modify the textEdit to compensate
        brackets_lib.add_brackets_via_semantic_token(vim.bo.filetype, item, function()
          require('blink.cmp.trigger.completion').show_if_on_trigger_character({ is_accept = true })
          require('blink.cmp.trigger.signature').show_if_on_trigger_character()
        end)
      else
        require('blink.cmp.trigger.completion').show_if_on_trigger_character({ is_accept = true })
        require('blink.cmp.trigger.signature').show_if_on_trigger_character()
      end

      -- Notify the rust module that the item was accessed
      require('blink.cmp.fuzzy').access(item)
    end)
    :catch(function(err) vim.notify(err, vim.log.levels.ERROR) end)
end

return accept
