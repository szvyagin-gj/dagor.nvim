# dagor.nvim

Tree-sitter highlighting in Neovim for the languages and data formats of the
[Dagor Engine](https://github.com/GaijinEntertainment/DagorEngine):

| Language | Files   | Grammar                                                                           |
| -------- | ------- | --------------------------------------------------------------------------------- |
| Quirrel  | `*.nut` | [tree-sitter-quirrel](https://github.com/GaijinEntertainment/tree-sitter-quirrel) |
| BLK      | `*.blk` | [tree-sitter-blk](https://github.com/GaijinEntertainment/tree-sitter-blk)         |
| Daslang  | `*.das` | [tree-sitter-daslang](https://github.com/GaijinEntertainment/tree-sitter-daslang) |

The plugin sets the filetypes, adds the parsers to nvim-treesitter and starts highlighting. A parser is
downloaded and built the first time you open a file of its language.

## Requirements

- Neovim 0.12 or newer
- [nvim-treesitter](https://github.com/nvim-treesitter/nvim-treesitter) on the `main` branch
- The `tree-sitter` CLI, a C compiler, `curl` and `tar` (nvim-treesitter uses them to build the parsers)

Run `:checkhealth dagor` to check all of these.

## Installation

With [lazy.nvim](https://github.com/folke/lazy.nvim):

```lua
{
  "szvyagin-gj/dagor.nvim",
  dependencies = { "nvim-treesitter/nvim-treesitter" },
  opts = {},
}
```

With [vim-plug](https://github.com/junegunn/vim-plug):

```vim
Plug 'nvim-treesitter/nvim-treesitter', {'branch': 'main', 'do': ':TSUpdate'}
Plug 'szvyagin-gj/dagor.nvim'
```

The plugin works with no setup call. To change an option, call `require("dagor").setup(opts)` or set `vim.g.dagor`
before the plugin loads.

## Options

These are the defaults:

```lua
require("dagor").setup({
  detect = true,     -- map *.nut, *.blk and *.das to the first filetype of their language
  install = true,    -- build a missing parser when its filetype opens
  highlight = true,  -- start tree-sitter highlighting in matching buffers
  filetypes = {      -- filetypes that use each language
    quirrel = { "quirrel" },
    blk = { "blk" },
    daslang = { "daslang" },
  },
  install_info = {}, -- override the parser source, see below
})
```

### Use the `squirrel` and `datablock` filetypes

Neovim detects `*.nut` as `squirrel`. The plugin changes it to `quirrel`. To keep your own filetype names:

```lua
require("dagor").setup({
  filetypes = { quirrel = { "squirrel" }, blk = { "datablock" } },
})
```

### Build the parsers from a local checkout

`install_info` is merged over the defaults. With `path`, nvim-treesitter builds the parser from the checkout and
links its `queries/` directory, so a change to `highlights.scm` applies when you open the next buffer:

```lua
require("dagor").setup({
  install_info = {
    quirrel = { path = "~/code/tree-sitter-quirrel" },
    blk = { path = "~/code/tree-sitter-blk" },
    daslang = { path = "~/code/tree-sitter-daslang" },
  },
})
```

After a change to a grammar, run `:TSInstall! quirrel blk daslang` to build the parsers again.

## Parsers and updates

The plugin pins each grammar to a release (Quirrel 4.43.2, BLK 1.0.0, Daslang 0.6.0). A new version of the plugin
moves the pins. Run `:TSUpdate` after you update the plugin.

To install all parsers at once, for example in a build step:

```lua
require("dagor").install():wait(300000)
```

## Limits

- The plugin does highlighting only. It has no indent, fold or injection queries.
- Binary BLK files are not text, and the grammar does not read them.

## Tests

`make test` runs a smoke test in an empty data directory. It downloads and builds all parsers from GitHub, so it
needs network access. Set `NVIM_TREESITTER` to your nvim-treesitter checkout if it is not in the default path.

## License

MIT. See [LICENSE](LICENSE).
