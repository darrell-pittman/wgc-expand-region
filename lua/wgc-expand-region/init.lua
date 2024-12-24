local t = function(str)
  return vim.api.nvim_replace_termcodes(str, true, true, true)
end

local ts = vim.treesitter
local v_modes = { 'v', 'vs', 'V', 'Vs' }
local select_msg = 'Node selected: %s'

--- Configuration table for wgc-expand-region plugin
--- @class Config
--- @field notify_on_expand boolean: Specifies whether to notify treesitter node type on visual expansion

local default_opts = {
  notify_on_expand = true,
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

--- Finds the next parent treesitter node whose range is larger
--- than the current visual selection
--- @param node TSNode?: Node at the beginning of the current visual selection
--- @param select_start string[]: Row and Col of start of current visual selection
--- @param select_end string[]: Row and Col of end of current visual selection
--- @return TSNode?: Returns found node or nil if no node has a range > current
--- visual selection
local function find_next_node(node, select_start, select_end)
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
  return find_next_node(node:parent(), select_start, select_end)
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
  default_opts = vim.tbl_deep_extend('force', default_opts, opts)
end

--- Expands current visual selection based on treesitter nodes
--- @return nil
M.expand_region = function()
  local mode = vim.fn.mode()
  local in_visual_mode = vim.iter(v_modes):any(function(vmode)
    return mode == vmode
  end)

  if not in_visual_mode then return end

  -- Go to normal mode to populate '< and '> marks of the current
  -- visual selection
  vim.cmd('normal! ' .. t('<esc>'))

  local select_start = vim.api.nvim_buf_get_mark(0, '<')
  local select_end = vim.api.nvim_buf_get_mark(0, '>')

  -- Set cursor to start of visual selection and retrieve treesitter node at
  -- that location and then find the next node up the tree
  vim.fn.setpos('.', { 0, select_start[1], select_start[2] + 1, 0 })
  local node = find_next_node(ts.get_node(), select_start, select_end)

  if not node then return end

  -- If end end of document then set end_col to go to very end
  local start_row, start_col, end_row, end_col = get_node_range(node)
  if end_row > vim.api.nvim_buf_line_count(0) then
    end_col = vim.api.nvim_get_vvar('maxcol')
  end

  -- Visually select range based on ts node returned by find_next_node
  vim.fn.setpos('.', { 0, start_row, start_col + 1, 0 })
  vim.cmd(string.format('normal %s', mode))
  vim.fn.setpos('.', { 0, end_row, end_col, 0 })

  if default_opts.notify_on_expand and node and node:named() then
    vim.notify(select_msg:format(node:type()), vim.log.levels.INFO)
  end
end

return M
