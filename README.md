# wgc-expand-region.nvim

A simple neovim plugin that has a function called expand_region that can
be mapped to a visual mode key combination to expand the visually 
selected region using nodes in the treesitter syntax tree. This works
similar to Control= in Emacs. There is also a contract_region function that
shrinks the visual selection based on previously expanded sections.

example mapping: 

```lua
vim.keymap.set('v', 'f', require('wgc-expand-region').expand_region)
vim.keymap.set('v', 'F', require('wgc-expand-region').contract_region)
```

With the above mapping, when you are in v or V mode and press 'f' the
selected region will expand to the parent node. Press 'f'
again and the selected region will expand again. If you press 'F' the expanded
region will be contracted to the previous selection.

Note: This plugin is not nearly as useful as mini.ai but it is a simple way
to expand selections to identifiers, statements, blocks, functions, etc.

Note: This plugin only works for visual and visual-line modes (v or V).
It makes no sense to expand a v-block region with treesitter nodes.

## Installation

### Lazy
```lua
  {
    'darrell-pittman/wgc-expand-region.nvim',
    opts = {
      notify_on_expand = true,
      stack_capacity = 20,
    }
  }
```

## Settings

There are two settings: 
* notify_on_expand - A boolean to turn on/off a notification of the node type
when the node is selected.  Defaults to true
* stack_capacity - How many StackNodes can be stored. Set it to the max number
of visual expansions that are possible in one file. Defaults to 20 (This should
be plenty unless you have some extremely nested code).


