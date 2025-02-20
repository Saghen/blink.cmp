local emmet_hack = {}

--- @param response blink.cmp.CompletionResponse
function emmet_hack.process_response(response)
  response.is_incomplete_forward = true
  for _, item in ipairs(response.items) do
    item.score_offset = -6 -- Negate exact match bonus plus some extra
  end
end

return emmet_hack
