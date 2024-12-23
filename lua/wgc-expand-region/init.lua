local t = require('wgc-nvim-utils').utils.t
local tbl = require('wgc-nvim-utils').utils.table
local ts = vim.treesitter
local v_modes = { 'v', 'vs', 'V', 'Vs', t('<C-V>'), t('<C-Vs>') }
local select_msg = 'Node selected: %s'

local default_opts = {
  notify_on_expand = true,
}

local function find_next_node(node, select_start)
  if not node then return end

  local start_row, start_col = node:range()
  if select_start[1] ~= (start_row + 1) or select_start[2] ~= (start_col) then
    return node
  end
  return find_next_node(node:parent(), select_start)
end

local M = {}

M.setup = function(opts)
  opts = opts or {}
  if not ts then
    M.expand_region = function()
      vim.notify('Treesitter required to run wgc-expand-region', vim.log.levels.ERROR)
    end
  end
  default_opts = tbl.merge(default_opts, opts)
end

M.expand_region = function()
  local mode = vim.fn.mode()
  local in_visual_mode = vim.iter(v_modes):fold(false, function(acc, vmode)
    return acc or mode == vmode
  end)

  if not in_visual_mode then
    return
  end

  local normal_mode = 'normal! ' .. t('<esc>')
  vim.cmd(normal_mode)
  local select_start = vim.api.nvim_buf_get_mark(0, '<')
  vim.fn.setpos('.', { 0, select_start[1], select_start[2] + 1, 0 })
  local node = find_next_node(ts.get_node(), select_start)

  if not node then return end
  local start_row, start_col, end_row, end_col = node:range()
  vim.fn.setpos('.', { 0, start_row + 1, start_col + 1, 0 })
  if end_col == 0 then
    local cmd = 'normal v' .. t('<c-end>')
    vim.cmd(cmd)
  else
    vim.cmd [[normal v]]
    vim.fn.setpos('.', { 0, end_row + 1, end_col, 0 })
  end
  if default_opts.notify_on_expand and node and node:named() then
    vim.notify(select_msg:format(node:type()), vim.log.levels.INFO)
  end
end

return M
