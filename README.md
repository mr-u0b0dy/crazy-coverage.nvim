# crazy-coverage.nvim

A Neovim plugin for displaying code coverage overlays directly in your editor using virtual text and configurable colors.

## Features

- **Multi-Format Support**: LCOV, LLVM JSON, Cobertura XML, GCOV, LLVM Profdata
- **Virtual Text Overlay**: Display hit counts and branch coverage inline
- **Auto-Detection**: Automatically detects coverage format from file extension
- **Configurable**: Customize colors, position, and display options
- **Two-Layer Architecture**: Decoupled parsers and converters for easy extension

## Installation

### Using [lazy.nvim](https://github.com/folke/lazy.nvim)

```lua
{
  "mr-u0b0dy/crazy-coverage.nvim",
  config = function()
    require("crazy-coverage").setup()
  end,
}
```

### Using [packer.nvim](https://github.com/wbthomason/packer.nvim)

```lua
use {
  "mr-u0b0dy/crazy-coverage.nvim",
  config = function()
    require("crazy-coverage").setup()
  end,
}
```

### Using [vim-plug](https://github.com/junegunn/vim-plug)

```vim
Plug "mr-u0b0dy/crazy-coverage.nvim"
```

Then add to your config:
```lua
require("crazy-coverage").setup()
```

### AstroVim Configuration

For AstroVim users, check out the complete example configuration with keybindings at:
[examples/astrovim-config.lua](examples/astrovim-config.lua)

Place this file in `~/.config/nvim/lua/plugins/crazy-coverage.lua` to get started with:
- **`<leader>l`** prefix for coverage management (load, toggle, enable, disable, clear)
- **`{c/}c`** to navigate between covered lines
- **`{p/}p`** to navigate between partially covered lines
- **`{u/}u`** to navigate between uncovered lines

## Quick Start

```lua
-- Load coverage file (auto-detects format)
:CoverageLoad coverage.lcov

-- Toggle coverage overlay
:CoverageToggle

-- Clear coverage
:CoverageClear

-- Navigate through coverage
:CoverageNextUncovered   " Jump to next uncovered line
:CoveragePrevCovered     " Jump to previous covered line
:CoverageNextPartial     " Jump to next partially covered line
```

## Configuration

```lua
require("crazy-coverage").setup({
  virt_text_pos = "eol",           -- "eol", "inline", "overlay", "right_align"
  show_hit_count = true,            -- Show hit counts
  show_branch_summary = false,      -- Show branch coverage as b:taken/total
  auto_load = true,                 -- Auto-load on file open
})
```

## Documentation

- [Usage Guide](doc/usage.md) - Commands, configuration, and examples
- [Supported Formats](doc/formats.md) - Coverage format details and generation
- [Architecture](doc/architecture.md) - Plugin design and extension guide
- [Development](doc/development.md) - Testing and contributing

## Requirements

- Neovim 0.7+
- Optional: `lcov` (for GCOV support)
- Optional: `llvm-profdata` and `llvm-cov` (for LLVM Profdata support)

## License

Apache License 2.0 - See [LICENSE](LICENSE) file for details.

**Copyright © 2025** - mr-u0b0dy

## Contributing

See [doc/development.md](doc/development.md) for testing and contribution guidelines.
