# crazy-coverage.nvim

A Neovim plugin for displaying code coverage overlays directly in your editor with smart auto-loading and file watching.

## Features

- **Multi-Format Support**: LCOV, LLVM JSON, Cobertura XML, GCOV, LLVM Profdata
- **Smart Toggle**: Single command auto-loads coverage and watches for changes
- **Virtual Text Overlay**: Display hit counts and branch coverage inline
- **Configurable**: Customize colors, position, and display options
- **Navigation**: Jump between covered/uncovered/partial lines

## Supported Languages

- **C/C++** - GCC (gcov/lcov), LLVM/Clang
- **Any Language** - Via LCOV, Cobertura XML, or LLVM JSON formats

The plugin supports any language that can generate coverage in one of the supported formats.

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

See [Installation Guide](doc/installation.md) for other plugin managers and AstroVim setup.

## Quick Start

```lua
-- Toggle coverage (auto-loads file, watches for changes)
:CoverageToggle

-- Navigate uncovered code
}cu  " Next uncovered line
{cu  " Previous uncovered line
```

**What the toggle does:**
- Finds and loads coverage file automatically
- Enables overlay with line highlighting  
- Watches file for changes (auto-reloads)
- Shows notifications on updates
- Cleans up everything when disabled

## Automatic Coverage File Discovery

The plugin intelligently finds your coverage file automatically. It:

1. **Searches Standard Directories** in order:
   - `build/coverage/` - CMake build output
   - `coverage/` - Standard coverage directory
   - `build/` - Build directory root
   - `.` - Project root

2. **Detects by Content** - Not just filenames:
   - Finds LCOV files (even if not named `*.lcov`)
   - Finds JSON coverage reports (even with custom names)
   - Finds Cobertura XML files (regardless of filename)
   - Finds GCOV/LLVM Profdata binary files

3. **Supports Any Filename**:
   ```
   ✓ build/coverage_report              (no extension)
   ✓ coverage_2025_01_09.json           (custom name)
   ✓ results.xml                        (non-standard name)
   ✓ my_coverage_data                   (any name works)
   ```

You can customize the search directories in config:

```lua
require("crazy-coverage").setup({
  coverage_dirs = {
    "build/coverage",      -- Search here first
    ".coverage",           -- Custom location
    "coverage",
    ".",
  }
})
```

See [Configuration Reference](doc/configuration.md#file-detection) for more details.

## Configuration

### Basic Setup

```lua
require("crazy-coverage").setup({
  default_show_hit_count = true,  -- Show hit counts by default
  virt_text_pos = "eol",          -- "eol", "inline", "overlay", "right_align"
  auto_adapt_colors = true,       -- Auto-adapt colors to your theme
})
```

### Common Configurations

```lua
-- Right-aligned with branch coverage
require("crazy-coverage").setup({
  virt_text_pos = "right_align",
  show_branch_summary = true,
})

-- Custom colors (disable auto-adaptation)
require("crazy-coverage").setup({
  auto_adapt_colors = false,
  colors = {
    covered = { bg = "#1a4d1a", fg = "#66ff66" },
    uncovered = { bg = "#4d1a1a", fg = "#ff6666" },
    partial = { bg = "#4d4d1a", fg = "#ffff66" },
  },
})

-- Auto-adapt with one manual override
require("crazy-coverage").setup({
  auto_adapt_colors = true,  -- Adapt most colors
  colors = {
    uncovered = "#660000",   -- But always use dark red for uncovered
  },
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
