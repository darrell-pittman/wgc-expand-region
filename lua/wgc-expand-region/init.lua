local t = require('wgc-nvim-utils').utils.t
local tbl = require('wgc-nvim-utils').utils.table
local ts = vim.treesitter
local v_modes = { 'v', 'vs', 'V', 'Vs', t('<C-V>'), t('<C-Vs>') }
local select_msg = 'Node selected: %s'

local expand_opts = {
  notify_on_expand = true,
}

local M = {}

M.setup = function(opts)
  opts = opts or {}
  if not ts then
    M.expand_region = function()
      vim.notify('Treesitter required to run wgc-expand-region', vim.log.levels.ERROR)
    end
  end
  expand_opts = tbl.merge(expand_opts, opts)
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
  local start = vim.api.nvim_buf_get_mark(0, '<')
  vim.fn.setpos('.', { 0, start[1], start[2] + 1, 0 })
  local node = ts.get_node()
  if node then
    local start_row, start_col, end_row, end_col = node:range()
    while node and start[1] == (start_row + 1) and start[2] == (start_col) do
      node = node:parent()
      if not node then break end
      start_row, start_col, end_row, end_col = node:range()
    end
    vim.fn.setpos('.', { 0, start_row + 1, start_col + 1, 0 })
    if end_col == 0 then
      local cmd = 'normal v' .. t('<c-end>')
      vim.cmd(cmd)
    else
      vim.cmd [[normal v]]
      vim.fn.setpos('.', { 0, end_row + 1, end_col, 0 })
    end
    if expand_opts.notify_on_expand and node and node:named() then
      vim.notify(select_msg:format(node:type()), vim.log.levels.INFO)
    end
  end
end

return M
