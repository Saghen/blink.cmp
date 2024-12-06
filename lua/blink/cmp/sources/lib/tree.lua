--- @class blink.cmp.SourceTreeNode
--- @field id string
--- @field source blink.cmp.SourceProvider
--- @field dependencies blink.cmp.SourceTreeNode[]
--- @field dependents blink.cmp.SourceTreeNode[]

local utils = require('blink.cmp.lib.utils')
local async = require('blink.cmp.lib.async')
local tree = {}

--- @param context blink.cmp.Context
--- @param all_sources blink.cmp.SourceProvider[]
function tree.new(context, all_sources)
  -- only include enabled sources for the given context
  local global_source_ids = require('blink.cmp.sources.lib').get_enabled_provider_ids(context)
  local sources = vim.tbl_filter(
    function(source) return vim.tbl_contains(global_source_ids, source.id) and source:enabled(context) end,
    all_sources
  )
  local source_ids = vim.tbl_map(function(source) return source.id end, sources)

  -- create a node for each source
  local nodes = vim.tbl_map(
    function(source) return { id = source.id, source = source, dependencies = {}, dependents = {} } end,
    sources
  )

  -- build the tree
  for idx, source in ipairs(sources) do
    local node = nodes[idx]
    for _, fallback_source_id in ipairs(source.config.fallbacks(context, source_ids)) do
      local fallback_node = nodes[utils.index_of(source_ids, fallback_source_id)]
      if fallback_node ~= nil then
        table.insert(node.dependents, fallback_node)
        table.insert(fallback_node.dependencies, node)
      end
    end
  end

  -- circular dependency check
  for _, node in ipairs(nodes) do
    tree.detect_cycle(node)
  end

  return setmetatable({ nodes = nodes }, { __index = tree })
end

function tree:get_top_level_nodes()
  local top_level_nodes = {}
  for _, node in ipairs(self.nodes) do
    if #node.dependencies == 0 then table.insert(top_level_nodes, node) end
  end
  return top_level_nodes
end

function tree:get_completions(context)
  local nodes_falling_back = {}

  --- @param node blink.cmp.SourceTreeNode
  local function get_completions_for_node(node)
    -- check that all the dependencies have been triggered, and are falling back
    for _, dependency in ipairs(node.dependencies) do
      if not nodes_falling_back[dependency.id] then return async.task.new(function(resolve) resolve() end) end
    end

    return node.source:get_completions(context):map(function(result)
      if #result.response.items ~= 0 or #node.dependents == 0 then
        return { node = node, cached = result.cached, response = result.response }
      end

      -- run dependents if the source returned 0 items
      nodes_falling_back[node.id] = true
      local tasks = vim.tbl_map(function(dependent) return get_completions_for_node(dependent) end, node.dependents)
      return async.task.await_all(tasks)
    end)
  end

  -- run the top level nodes and let them fall back to their dependents if needed
  local tasks = vim.tbl_map(function(node) return get_completions_for_node(node) end, self:get_top_level_nodes())

  return async.task.await_all(tasks):map(function(results)
    local cached = true
    local responses = {}
    for _, result in ipairs(utils.flatten(results)) do
      cached = cached and result.cached
      responses[result.node.id] = result.response
    end
    return { cached = cached, responses = responses }
  end)
end

--- Helper function to detect cycles using DFS
--- @param node blink.cmp.SourceTreeNode
--- @param visited? table<string, boolean>
--- @param path? table<string, boolean>
--- @return boolean
function tree.detect_cycle(node, visited, path)
  visited = visited or {}
  path = path or {}

  if path[node.id] then
    -- Found a cycle - construct the cycle path for error message
    local cycle = { node.id }
    for id, _ in pairs(path) do
      table.insert(cycle, id)
    end
    error('Circular dependency detected: ' .. table.concat(cycle, ' -> '))
  end

  if visited[node.id] then return false end

  visited[node.id] = true
  path[node.id] = true

  for _, dependent in ipairs(node.dependents) do
    if tree.detect_cycle(dependent, visited, path) then return true end
  end

  path[node.id] = nil
  return false
end

return tree
