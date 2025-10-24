local recency = {
  is_tracking = false,
  --- @type table<number, number>
  bufs = {},
}

function recency.start_tracking()
  if recency.is_tracking then return end
  recency.is_tracking = true
end

function recency.accessed_at(bufnr) return recency.bufs[bufnr] or 0 end

return recency
