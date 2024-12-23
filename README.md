# wgc-expand-region

A simple plugin that has a function called expand-region that can
be mapped to a visual mode key combination to expand the visually 
selected region using nodes in the treesitter syntax tree. This works
similar to Control= in Emacs. 

example mapping: 

vim.keymap.set('v', '\<space\>\<space\>', require('wgc-expand-region').expand-region)

With the above mapping, when you are in v mode and press \<space\>\<space\>
the selected region will expand to the parent node. Press \<space\>\<space\>
again and the selected region will expand again.

Note: This plugin is not nearly as useful as mini.ai but it is a simple way
to expand selections to identifiers, blocks, functions, etc.

## Installation

### Lazy
```lua
  {
    'darrell-pittman/wgc-expand-region',
    dependencies = {
      {
        'darrell-pittman/wgc-nvim-utils'
      }
    },
    opts = {
      notify_on_expand = true,
    }
  }
```

## Settings

There is only one setting: 
* notify_on_expand - A boolean to turn on/off a notification of the node type
when the node is selected.  Defaults to true


