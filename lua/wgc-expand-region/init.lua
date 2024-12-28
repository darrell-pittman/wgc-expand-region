-- A stack that holds data for highlighted nodes
local nodes

-- True while we are expanding or collapsing
local expanding = false

--- A utility function to replace termcodes
--- @param str string: String for which termcodes will be replaced
local t = function(str)
  return vim.api.nvim_replace_termcodes(str, true, true, true)
end

-- convenience var
local ts = vim.treesitter

-- list of visual modes that allow expansion
local v_modes = { 'v', 'vs', 'V', 'Vs' }

-- Notify msg
local select_msg = 'Node selected: %s'

--- Configuration table for wgc-expand-region plugin
--- @class Config
--- @field notify_on_expand boolean: Specifies whether to notify treesitter node type on visual expansion
--- @field stack_capacity integer: Capacity of node stack

local default_opts = {
  notify_on_expand = true,
  stack_capacity = 20,
}

--- Gets range for node with rows adjusted to 1-based index
--- @param node TSNode: node for which range is sought
--- @return integer, integer, integer, integer: Start Row, Start Col, End Row, End Col
local function get_node_range(node)
  local sr, sc, er, ec = node:range()
  sr = (sr or 0) + 1
  sc = sc or 0
  er = (er or 0) + 1
  ec = ec or 0
  return sr, sc, er, ec
end

--- Stack Node
--- @class StackNode
--- @field start_row integer: Start Row of stack node
--- @field start_col integer: Start Column of stack node
--- @field end_row integer: End Row of stack node
--- @field end_col integer: End Column of stack node
--- @field type integer: Type of stack node

--- Compares 2 stack nodes for equality
--- @param node_1 StackNode: StackNode to be compared for equality
--- @param node_2 StackNode: StackNode to be compared for equality
--- @return boolean: True if node_1 == node_2
local function stack_nodes_eq(node_1, node_2)
  for k, v in pairs(node_1) do
    if v ~= node_2[k] then
      return false
    end
  end
  return true
end

--- Creates StackNode from TSNode
--- @param node TSNode: TSNode to be converted to StackNode
--- @return StackNode
local function create_stack_node(node)
  local start_row, start_col, end_row, end_col = get_node_range(node)
  return {
    start_row = start_row,
    start_col = start_col,
    end_row = end_row,
    end_col = end_col,
    type = node:type(),
  }
end

--- Finds the next parent treesitter node whose range is larger
--- than the current visual selection
--- @param node TSNode?: Node at the beginning of the current visual selection
--- @param select_start string[]: Row and Col of start of current visual selection
--- @param select_end string[]: Row and Col of end of current visual selection
--- @return TSNode?: Returns found node or nil if no node has a range > current
--- visual selection
local function find_parent_node(node, select_start, select_end)
  if not node then return end

  local node_start_row, node_start_col, node_end_row, node_end_col = get_node_range(node)

  local select_start_row = select_start[1]
  local select_start_col = select_start[2]
  local select_end_row = select_end[1]
  local select_end_col = select_end[2]

  local node_exceeds_selection =
      (node_start_row < select_start_row)
      or ((node_start_row == select_start_row)
        and (node_start_col < select_start_col))
      or (node_end_row > select_end_row)
      or ((node_end_row == select_end_row) and
        (node_end_col > select_end_col + 1))

  if node_exceeds_selection then
    return node
  end
  return find_parent_node(node:parent(), select_start, select_end)
end

--- Pops last node off stack and returns peek at last node on stack
--- @return StackNode
local function find_child_node()
  nodes:pop()
  return nodes:peek()
end

-- @module wgc-expand-region
local M = {}

--- Setup options for wgc-expand-region.
--- @param opts Config: User config for wgc-expand-region.
--- @return nil
M.setup = function(opts)
  opts = opts or {}
  if not ts then
    M.expand_region = function()
      vim.notify('Treesitter required to run wgc-expand-region', vim.log.levels.ERROR)
    end
  end
  default_opts = vim.tbl_extend('force', default_opts, opts)
  nodes = require('wgc-expand-region.stack').new(default_opts.stack_capacity)
end

--- Clears the node stack unless expanding
--- @return nil
M.clear_stack = function()
  if not expanding then
    nodes:clear()
  end
end

--- Returns an iterator for the visual modes for which this plugin responds
--- @return Iter
M.visual_modes = function()
  return vim.iter(v_modes)
end

--- Expands or contracts visual selection
--- @param node_finder function: A function that receives a TSNode and visual
--- selection start and end and returns a StackNode
local function highlight_node(node_finder)
  local mode = vim.fn.mode()
  local in_visual_mode = vim.iter(v_modes):any(function(vmode)
    return mode == vmode
  end)

  if not in_visual_mode then return end

  expanding = true

  -- Go to normal mode to populate '< and '> marks of the current
  -- visual selection
  vim.cmd('normal! ' .. t('<esc>'))

  local select_start = vim.api.nvim_buf_get_mark(0, '<')
  local select_end = vim.api.nvim_buf_get_mark(0, '>')

  -- Set cursor to start of visual selection and call node_finder function
  -- that will return a StackNode that either expands or contracts the
  -- visual selection
  vim.fn.setpos('.', { 0, select_start[1], select_start[2] + 1, 0 })
  local node_data = node_finder(ts.get_node(), select_start, select_end)

  if not node_data then
    expanding = false
    return
  end

  local end_col = node_data.end_col

  -- If end end of document then set end_col to go to very end
  if node_data.end_row > vim.api.nvim_buf_line_count(0) then
    end_col = vim.api.nvim_get_vvar('maxcol')
  end

  -- Visually select range based on StackNode returned by node_finder
  vim.fn.setpos('.', { 0, node_data.start_row, node_data.start_col + 1, 0 })
  vim.cmd(string.format('normal %s', mode))
  vim.fn.setpos('.', { 0, node_data.end_row, end_col, 0 })

  expanding = false

  -- Notify type of node that has been highlighted
  if default_opts.notify_on_expand then
    vim.notify(select_msg:format(node_data.type), vim.log.levels.INFO)
  end
end

--- Expands current visual selection based on treesitter nodes
--- @return nil
M.expand_region = function()
  highlight_node(function(node, select_start, select_end)
    local found = find_parent_node(node, select_start, select_end)
    if found then
      local current_node = create_stack_node(found)
      local prev_node = nodes:peek()

      local nodes_eq = prev_node and stack_nodes_eq(current_node, prev_node)

      if not nodes_eq then
        nodes:push(current_node)
      end
    end
    return nodes:peek()
  end)
end

--- Contracts current visual selection to previous visual selection
--- @return nil
M.contract_region = function()
  highlight_node(find_child_node)
end

return M
