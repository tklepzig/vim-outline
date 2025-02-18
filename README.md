# Discontinued

# vim-outline

TODO

DESCRIPTION

SCREENSHOT

## Installation

### [Vundle](https://github.com/gmarik/Vundle.vim)

1.  Add the following configuration to your `.vimrc`.

        Plugin 'tklepzig/vim-outline'

2.  Install with `:BundleInstall`.

### [NeoBundle](https://github.com/Shougo/neobundle.vim)

1.  Add the following configuration to your `.vimrc`.

        NeoBundle 'tklepzig/vim-outline'

2.  Install with `:NeoBundleInstall`.

### [Plug](https://github.com/junegunn/vim-plug)

1.  Add the following configuration to your `.vimrc`.

        Plug 'tklepzig/vim-outline'

2.  Install with `:PlugInstall`.

## Usage

TODO
Uses vim9script, so vim version >= 9.0 necessary.

For rules config add vim9script at top of your .vimrc

Command: OutlineToggle, no mapping, if u want one:

    nnoremap <silent> <leader>o :OutlineToggle<cr>

Configure Rules either merge or from zero

Inside the outline window the following mappings exists:

| Key               | Function                                                                  |
| ----------------- | ------------------------------------------------------------------------- |
| <kbd>o</kbd>      | TODO                                                                      |
| <kbd>Return</kbd> | Same as <kbd>o</kbd>                                                      |
| <kbd>p</kbd>      | TODO                                                                      |
| <kbd>z</kbd>      | Toggle zoom (increase width/height of outline window to max width/height) |
| <kbd>m</kbd>      | Toggle outline window between vertical or horizontal split                |

## Documentation

You can view the full manual (including customization options) with `:help outline`.

## Contribution

Have a feature request or found a bug? Open an issue at https://github.com/tklepzig/vim-outline/issues.
