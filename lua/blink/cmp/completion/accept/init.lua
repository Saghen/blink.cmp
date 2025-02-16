local config = require('blink.cmp.config').completion.accept
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
    .resolve(ctx, item)
    -- Some LSPs may take a long time to resolve the item, so we timeout
    :timeout(config.resolve_timeout_ms)
    -- and use the item as-is
    :catch(function() return item end)
    :map(function(item)
      item = vim.deepcopy(item)

      -- Get additional text edits, converted to utf-8
      local all_text_edits = vim.deepcopy(item.additionalTextEdits or {})
      all_text_edits = vim.tbl_map(
        function(text_edit) return text_edits_lib.to_utf_8(text_edit, text_edits_lib.offset_encoding_from_item(item)) end,
        all_text_edits
      )

      -- TODO: it's not obvious that this is converting to utf-8
      item.textEdit = text_edits_lib.get_from_item(item)

      -- Create an undo point, if it's not a snippet, since the snippet engine should handle undo
      if
        ctx.mode == 'default'
        and require('blink.cmp.config').completion.accept.create_undo_point
        and item.insertTextFormat ~= vim.lsp.protocol.InsertTextFormat.Snippet
        -- HACK: We check the kind here because the Luasnip source returns PlainText and handles
        -- expansion itself. Otherwise, Luasnip will fail to enter select mode
        -- https://github.com/Saghen/blink.cmp/commit/284dd37f9bbc632f8281d6361e877db5b45e6ff0#r150498482
        and item.kind ~= require('blink.cmp.types').CompletionItemKind.Snippet
      then
        -- setting the undolevels forces neovim to create an undo point
        vim.o.undolevels = vim.o.undolevels
      end

      -- Ignore snippets that only contain text
      -- FIXME: doesn't handle escaped snippet placeholders "\\$1" should output "$1", not "\$1"
      if
        item.insertTextFormat == vim.lsp.protocol.InsertTextFormat.Snippet
        and item.kind ~= require('blink.cmp.types').CompletionItemKind.Snippet
      then
        local parsed_snippet = require('blink.cmp.sources.snippets.utils').safe_parse(item.textEdit.newText)
        if
          parsed_snippet ~= nil
          and #parsed_snippet.data.children == 1
          and parsed_snippet.data.children[1].type == vim.lsp._snippet_grammar.NodeType.Text
        then
          item.insertTextFormat = vim.lsp.protocol.InsertTextFormat.PlainText
          item.textEdit.newText = tostring(parsed_snippet)
        end
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
        text_edits_lib.apply(temp_text_edit, all_text_edits)

        -- Expand the snippet
        require('blink.cmp.config').snippets.expand(item.textEdit.newText)

      -- OR Normal: Apply the text edit and move the cursor
      else
        local new_cursor = text_edits_lib.get_apply_end_position(item.textEdit, all_text_edits)
        new_cursor[2] = new_cursor[2]

        text_edits_lib.apply(item.textEdit, all_text_edits)

        if ctx.get_mode() ~= 'term' then ctx.set_cursor(new_cursor) end
        text_edits_lib.move_cursor_in_dot_repeat(offset)
      end

      -- Let the source execute the item itself
      sources.execute(ctx, item):map(function()
        -- Check semantic tokens for brackets, if needed, and apply additional text edits
        if brackets_status == 'check_semantic_token' then
          -- TODO: since we apply the additional text edits after, auto imported functions will not
          -- get auto brackets. If we apply them before, we have to modify the textEdit to compensate
          brackets_lib.add_brackets_via_semantic_token(ctx, vim.bo.filetype, item, function()
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
        require('blink.cmp.fuzzy').access(item)
      end)
    end)
    :catch(function(err) vim.notify(err, vim.log.levels.ERROR, { title = 'blink.cmp' }) end)
end

return accept
