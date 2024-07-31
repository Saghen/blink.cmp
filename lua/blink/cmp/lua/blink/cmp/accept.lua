local utils = {}

local function accept(item)
  -- create an undo point
  -- fixme: doesnt work
  -- vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes('<C-G>u', true, false, true), 'n', false)
  -- vim.cmd('normal! i<C-G>u')
  -- vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes('<C-G>u', true, false, true), 'im', true)

  local sources = require('blink.cmp.sources')
  local fuzzy = require('blink.cmp.fuzzy')

  local text_edit = item.textEdit
  if text_edit ~= nil then
    -- Adjust the position of the text edit to be the current cursor position
    -- since the data might be outdated. We compare the cursor column position
    -- from when the items were fetched versus the current.
    -- hack: figure out a better way
    local offset = vim.api.nvim_win_get_cursor(0)[2] - item.cursor_column
    text_edit.range['end'].character = text_edit.range['end'].character + offset
  else
    -- No text edit so we fallback to our own resolution
    text_edit = utils.guess_text_edit(vim.api.nvim_get_current_buf(), item)
  end

  -- Snippet
  if item.insertTextFormat == vim.lsp.protocol.InsertTextFormat.Snippet then
    -- We want to handle offset_encoding and the text edit api can do this for us
    -- so we empty the newText and apply
    local temp_text_edit = vim.deepcopy(text_edit)
    temp_text_edit.newText = ''
    utils.apply_text_edits(item.client_id, { temp_text_edit })

    -- Expand the snippet
    -- todo: use the snippet plugin api
    vim.snippet.expand(text_edit.newText)
  else
    -- Apply the text edit and move the cursor
    utils.apply_text_edits(item.client_id, { text_edit })
    vim.api.nvim_win_set_cursor(
      0,
      { text_edit.range.start.line + 1, text_edit.range.start.character + #text_edit.newText }
    )
  end

  -- Apply additional text edits
  -- LSPs can either include these in the initial response or require a resolve
  -- These are used for things like auto-imports
  -- todo: check capabilities to know ahead of time
  if item.additionalTextEdits ~= nil then
    utils.apply_text_edits(item.client_id, item.additionalTextEdits)
  else
    sources.resolve(
      item,
      function(resolved_item) utils.apply_text_edits(item.client_id, (resolved_item or item).additionalTextEdits or {}) end
    )
  end

  -- Notify the rust module that the item was accessed
  fuzzy.access(item)
end

---------- UTILS ------------

function utils.guess_text_edit(bufnr, item)
  local word = item.insertText or item.label

  local current_line = vim.api.nvim_win_get_cursor(0)[1]
  local current_col = vim.api.nvim_win_get_cursor(0)[2]
  local line = vim.api.nvim_buf_get_lines(bufnr, current_line - 1, current_line, false)[1]

  -- Search forward/backward for the start/end of the word
  local start_col = current_col
  while start_col > 1 do
    local char = line:sub(start_col, start_col)
    if char:match('[%w_\\-]') == nil then
      start_col = start_col + 1
      break
    end
    start_col = start_col - 1
  end

  -- todo: dont search forward since LSPs dont typically do this so it will be inconsistent
  local end_col = current_col
  while end_col < #line do
    local char = line:sub(end_col + 1, end_col + 1)
    if char:match('[%w_\\-]') == nil then break end
    end_col = end_col + 1
  end

  -- convert to 0-index
  return {
    range = {
      start = { line = current_line - 1, character = start_col - 1 },
      ['end'] = { line = current_line - 1, character = end_col },
    },
    newText = word,
  }
end

function utils.apply_text_edits(client_id, edits)
  local client = vim.lsp.get_client_by_id(client_id)
  local offset_encoding = client ~= nil and client.offset_encoding or 'utf-16'
  vim.lsp.util.apply_text_edits(edits, vim.api.nvim_get_current_buf(), offset_encoding)
end

return accept
