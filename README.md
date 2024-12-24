# wgc-expand-region.nvim

A simple neovim plugin that has a function called expand-region that can
be mapped to a visual mode key combination to expand the visually 
selected region using nodes in the treesitter syntax tree. This works
similar to Control= in Emacs. 

example mapping: 

```lua
vim.keymap.set('v', '<space><space>', require('wgc-expand-region').expand-region)
```

With the above mapping, when you are in v or V mode and press \<space\>\<space\>
the selected region will expand to the parent node. Press \<space\>\<space\>
again and the selected region will expand again.

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
    }
  }
```

## Settings

There is only one setting: 
* notify_on_expand - A boolean to turn on/off a notification of the node type
when the node is selected.  Defaults to true


