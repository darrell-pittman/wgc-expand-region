local expand_region = require('wgc-expand-region')

-- Create auto command pattern from expand-region visual modes
local pattern = expand_region.visual_modes():map(function(mode)
  return mode .. ':*'
end):totable()

print(vim.inspect(pattern))

local group = vim.api.nvim_create_augroup(
  'WgcExpandRegionGroup',
  { clear = true })

-- When we leave visual mode and we are not currently expanding or collapsing
-- then clear the node stack
vim.api.nvim_create_autocmd('ModeChanged', {
  group = group,
  pattern = pattern,
  callback = function()
    if not expand_region.is_expanding() then
      expand_region.clear_stack()
    end
  end
})
