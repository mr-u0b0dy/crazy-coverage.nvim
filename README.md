# crazy-coverage.nvim

A Neovim plugin for displaying code coverage overlays directly in your editor with smart auto-loading and file watching.

## Features

- **Multi-Format Support**: LCOV, LLVM JSON, Cobertura XML, GCOV, LLVM Profdata
- **Smart Toggle**: Single command auto-loads coverage and watches for changes
- **Virtual Text Overlay**: Display hit counts and branch coverage inline
- **Configurable**: Customize colors, position, and display options
- **Navigation**: Jump between covered/uncovered/partial lines

## Installation

### lazy.nvim

```lua
{
  "mr-u0b0dy/crazy-coverage.nvim",
  config = function()
    require("crazy-coverage").setup()
  end,
}
```

### packer.nvim

```lua
use {
  "mr-u0b0dy/crazy-coverage.nvim",
  config = function()
    require("crazy-coverage").setup()
  end,
}
```

See [Installation Guide](doc/installation.md) for other plugin managers and AstroVim setup.

## Quick Start

```lua
-- Toggle coverage (auto-loads file, watches for changes)
:CoverageToggle

-- Navigate uncovered code
}u  " Next uncovered line
{u  " Previous uncovered line
```

**What the toggle does:**
- Finds and loads coverage file automatically
- Enables overlay with line highlighting  
- Watches file for changes (auto-reloads)
- Shows notifications on updates
- Cleans up everything when disabled

## Configuration

### Basic Setup

```lua
require("crazy-coverage").setup({
  default_show_hit_count = true,  -- Show hit counts by default
  virt_text_pos = "eol",          -- "eol", "inline", "overlay", "right_align"
})
```

### Common Configurations

```lua
-- Right-aligned with branch coverage
require("crazy-coverage").setup({
  virt_text_pos = "right_align",
  show_branch_summary = true,
})

-- Custom colors
vim.api.nvim_set_hl(0, "MyCovered", { bg = "#004400" })
require("crazy-coverage").setup({
  covered_hl = "MyCovered",
})
```

See [Configuration Reference](doc/configuration.md) for all 15+ options.

## Commands

| Command | Description |
|---------|-------------|
| `:CoverageToggle` | Toggle coverage overlay (auto-loads, watches file) |
| `:CoverageToggleHitCount` | Toggle hit count display |
| `:CoverageLoad <file>` | Manually load specific coverage file |
| `:CoverageNextUncovered` | Jump to next uncovered line |
| `:CoveragePrevCovered` | Jump to previous covered line |
| `:CoverageNextPartial` | Jump to next partially covered line |

See [Usage Guide](doc/usage.md) for keybindings and navigation.

## Documentation

- **[Installation Guide](doc/installation.md)** - Plugin managers and AstroVim setup
- **[Usage Guide](doc/usage.md)** - Commands, keybindings, and workflows
- **[Configuration Reference](doc/configuration.md)** - All config options
- **[Supported Formats](doc/formats.md)** - Coverage format details
- **[Coverage Examples](coverage-examples/)** - C/C++ examples with GCC/LLVM
- **[Architecture](doc/architecture.md)** - Plugin design guide
- **[Development](doc/development.md)** - Testing and contributing

## Requirements

- Neovim 0.7+
- Coverage files from your build system (lcov, llvm-cov, etc.)

## License

Apache License 2.0 - Copyright © 2025 mr-u0b0dy

## Contributing

See [Development Guide](doc/development.md) for testing and contribution guidelines.
