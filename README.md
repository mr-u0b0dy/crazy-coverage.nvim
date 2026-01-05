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
[config examples/astrovim-config.lua](config%20examples/astrovim-config.lua)

Place this file in `~/.config/nvim/lua/plugins/crazy-coverage.lua` to get started with:
- **`<leader>ct`** - Toggle coverage overlay (auto-loads, watches for changes)
- **`<leader>ch`** - Toggle hit count display
- **`}c` / `{c`** - Navigate to next/previous covered lines
- **`}p` / `{p`** - Navigate to next/previous partially covered lines
- **`}u` / `{u`** - Navigate to next/previous uncovered lines

## Quick Start

```lua
-- Toggle coverage overlay (auto-loads coverage file, watches for changes)
:CoverageToggle

-- Toggle hit count display
:CoverageToggleHitCount

-- Manually load specific coverage file (optional)
:CoverageLoad coverage.lcov

-- Navigate through coverage
:CoverageNextUncovered   " Jump to next uncovered line
:CoveragePrevCovered     " Jump to previous covered line
:CoverageNextPartial     " Jump to next partially covered line
```

### Smart Toggle Features

**When enabled** (`:CoverageToggle` or `<leader>ct`):
- Auto-finds and loads coverage file in project
- Enables overlay with line highlighting
- Shows hit counts (configurable via `default_show_hit_count`)
- Starts file watcher (checks every 2 seconds)
- Auto-reloads and notifies when coverage file changes

**When disabled** (`:CoverageToggle` again):
- Clears all overlays
- Stops file watching
- Cleans up all resources

## Configuration

### Basic Setup

```lua
require("crazy-coverage").setup({
  virt_text_pos = "eol",              -- Virtual text position
  default_show_hit_count = true,      -- Show hit counts by default when overlay enabled
  show_hit_count = true,              -- Current hit count display state
  show_branch_summary = false,        -- Show branch coverage as b:taken/total
  enable_line_hl = true,              -- Enable line highlighting
})
```

### All Configuration Options

```lua
require("crazy-coverage").setup({
  -- ===== Display Options =====
  
  -- Virtual text position for coverage information
  -- Options: "eol" (end of line), "inline", "overlay", "right_align"
  virt_text_pos = "eol",
  
  -- Show hit counts by default when coverage overlay is enabled
  -- Set to false if you want to manually toggle hit counts each time
  default_show_hit_count = true,
  
  -- Current state: show hit count in virtual text
  show_hit_count = true,
  
  -- Show percentage coverage for each line
  show_percentage = false,
  
  -- Show branch coverage summary per line (format: b:taken/total)
  -- Example: "b:2/4" means 2 out of 4 branches were taken
  show_branch_summary = false,
  
  -- Enable line highlighting (background colors)
  enable_line_hl = true,
  
  -- ===== Highlight Groups =====
  
  -- Highlight group names for covered/uncovered/partial lines
  -- You can customize these with your own highlight groups
  covered_hl = "CoverageCovered",      -- Green background by default
  uncovered_hl = "CoverageUncovered",  -- Red background by default
  partial_hl = "CoveragePartial",      -- Orange background by default
  
  -- ===== Auto-Loading =====
  
  -- Auto-load coverage when opening a file (deprecated: use CoverageToggle instead)
  auto_load = true,
  
  -- ===== Coverage File Detection =====
  
  -- Coverage file patterns to search for per language
  -- Plugin will look for these files in the project root
  coverage_patterns = {
    c = { "*.lcov", "coverage.json", "coverage.xml", "*.profdata" },
    cpp = { "*.lcov", "coverage.json", "coverage.xml", "*.profdata" },
  },
  
  -- Patterns used to find the project root directory
  -- Plugin searches upward from current file until it finds one of these
  project_markers = { 
    ".git", 
    "CMakeLists.txt", 
    "Makefile", 
    "compile_commands.json" 
  },
  
  -- ===== Cache Settings =====
  
  -- Enable caching of parsed coverage data
  cache_enabled = true,
  
  -- Directory for storing cached coverage data
  cache_dir = vim.fn.stdpath("cache") .. "/crazy-coverage.nvim",
})
```

### Configuration Examples

**Minimal Setup (Defaults)**
```lua
require("crazy-coverage").setup()
```

**Inline Hit Counts with No Branch Summary**
```lua
require("crazy-coverage").setup({
  virt_text_pos = "inline",
  show_hit_count = true,
  show_branch_summary = false,
})
```

**Right-Aligned with Branch Coverage**
```lua
require("crazy-coverage").setup({
  virt_text_pos = "right_align",
  show_hit_count = true,
  show_branch_summary = true,
})
```

**Custom Highlight Groups**
```lua
-- Define your own colors
vim.api.nvim_set_hl(0, "MyCovered", { bg = "#004400", fg = "#00FF00" })
vim.api.nvim_set_hl(0, "MyUncovered", { bg = "#440000", fg = "#FF0000" })
vim.api.nvim_set_hl(0, "MyPartial", { bg = "#444400", fg = "#FFFF00" })

require("crazy-coverage").setup({
  covered_hl = "MyCovered",
  uncovered_hl = "MyUncovered",
  partial_hl = "MyPartial",
})
```

**Manual Hit Count Control**
```lua
require("crazy-coverage").setup({
  default_show_hit_count = false,  -- Don't show hit counts by default
  -- Use <leader>ch to toggle hit counts on/off
})
```

## Documentation

- [Configuration Reference](doc/configuration.md) - Complete guide to all config options
- [Usage Guide](doc/usage.md) - Commands, configuration, and examples
- [Supported Formats](doc/formats.md) - Coverage format details and generation
- [Architecture](doc/architecture.md) - Plugin design and extension guide
- [Development](doc/development.md) - Testing and contributing
- [Coverage Examples](coverage-examples/) - C and C++ examples with GCC/LLVM/LCOV

## Coverage Examples

Get started quickly with the provided examples:

```bash
cd coverage-examples/c
make lcov           # Build, run, and generate LCOV coverage report
# Then in Neovim: :CoverageLoad build/coverage/coverage.lcov

# Or with LLVM:
make llvm-report    # Build, run, and generate LLVM JSON coverage
# Then in Neovim: :CoverageLoad build/coverage/coverage.json
```

See [coverage-examples/README.md](coverage-examples/README.md) for full details on:
- **C examples** with GCC coverage and LLVM coverage
- **C++ examples** with GCC coverage and LLVM coverage  
- Makefile targets for different coverage tools
- Step-by-step instructions for each tool

## Requirements

- Neovim 0.7+
- Optional: `lcov` (for GCOV support)
- Optional: `llvm-profdata` and `llvm-cov` (for LLVM Profdata support)

## License

Apache License 2.0 - See [LICENSE](LICENSE) file for details.

**Copyright © 2025** - mr-u0b0dy

## Contributing

See [doc/development.md](doc/development.md) for testing and contribution guidelines.
