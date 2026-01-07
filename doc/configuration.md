# Configuration Reference

Complete reference for all configuration options in crazy-coverage.nvim.

## Table of Contents

- [Setup](#setup)
- [Display Options](#display-options)
- [Highlight Groups](#highlight-groups)
- [File Detection](#file-detection)
- [Cache Settings](#cache-settings)
- [Complete Example](#complete-example)

## Setup

The plugin is configured by passing options to the `setup()` function:

```lua
require("crazy-coverage").setup({
  -- your options here
})
```

If called without arguments, all options use their default values.

## Display Options

### `virt_text_pos`

**Type:** `string`  
**Default:** `"eol"`  
**Options:** `"eol"`, `"inline"`, `"overlay"`, `"right_align"`

Position of virtual text showing coverage information.

- `"eol"` - Display at end of line
- `"inline"` - Display inline with the code
- `"overlay"` - Overlay on top of existing text
- `"right_align"` - Align to the right edge of the window

```lua
virt_text_pos = "eol"
```

### `default_show_hit_count`

**Type:** `boolean`  
**Default:** `true`

Controls whether hit counts are shown by default when the coverage overlay is enabled via `:CoverageToggle`. Set to `false` if you prefer to manually toggle hit counts each time using `<leader>ch`.

```lua
default_show_hit_count = true  -- Hit counts visible when overlay enabled
```

### `show_hit_count`

**Type:** `boolean`  
**Default:** `true`

Current state of hit count display. This is the runtime state that gets toggled with `:CoverageToggleHitCount`.

```lua
show_hit_count = true
```

### `show_percentage`

**Type:** `boolean`  
**Default:** `false`

Display coverage percentage for each line. When enabled, shows the percentage of execution count relative to the maximum in the file.

```lua
show_percentage = false
```

### `show_branch_summary`

**Type:** `boolean`  
**Default:** `false`

Show branch coverage summary per line in the format `b:taken/total`.

Example: `b:2/4` means 2 out of 4 branches on this line were executed.

```lua
show_branch_summary = false  -- Set to true to see branch coverage
```

### `enable_line_hl`

**Type:** `boolean`  
**Default:** `true`

Enable line highlighting with background colors. When enabled, covered lines get a green background, uncovered lines get red, and partially covered lines get orange.

```lua
enable_line_hl = true
```

## Highlight Groups

### `auto_adapt_colors`

**Type:** `boolean`  
**Default:** `true`

Automatically adapt coverage colors based on your current colorscheme. When enabled, the plugin detects whether you're using a dark or light theme and adjusts the coverage highlight colors accordingly.

- **Dark themes**: Uses lighter, saturated colors for better visibility
- **Light themes**: Uses darker, muted colors for comfortable reading

```lua
auto_adapt_colors = true  -- Automatically match your theme
```

Set to `false` to use manual color configuration:

```lua
require("crazy-coverage").setup({
  auto_adapt_colors = false,  -- Disable auto-adaptation
  colors = {
    -- Use your own colors
    covered = { bg = "#00AA00", fg = "#FFFFFF" },
    uncovered = { bg = "#FF0000", fg = "#FFFFFF" },
    partial = { bg = "#FFAA00", fg = "#FFFFFF" },
  },
})
```

### `colors`

**Type:** `table`  
**Default:** `{ covered = nil, uncovered = nil, partial = nil }`

Manual color overrides for coverage highlighting. Each color can be:
- A hex string: `"#00AA00"` (sets background only)
- A table: `{ bg = "#00AA00", fg = "#FFFFFF" }` (sets background and foreground)
- `nil` (uses auto-adapted colors if `auto_adapt_colors = true`)

```lua
-- Example 1: Simple hex colors (background only)
colors = {
  covered = "#004400",
  uncovered = "#440000",
  partial = "#444400",
}

-- Example 2: Full control with bg and fg
colors = {
  covered = { bg = "#003300", fg = "#00FF00" },
  uncovered = { bg = "#330000", fg = "#FF4444" },
  partial = { bg = "#332200", fg = "#FFAA00" },
}

-- Example 3: Override only specific colors, let others adapt
colors = {
  covered = nil,          -- Auto-adapt
  uncovered = "#330000",  -- Manual red
  partial = nil,          -- Auto-adapt
}
```

### `covered_hl`

**Type:** `string`  
**Default:** `"CoverageCovered"`

Highlight group name for covered lines. The plugin creates this highlight group automatically based on `auto_adapt_colors` and `colors` settings.

You can also define your own highlight group:

```lua
vim.api.nvim_set_hl(0, "MyCovered", { bg = "#004400", fg = "#00FF00" })

require("crazy-coverage").setup({
  covered_hl = "MyCovered"
})
```

### `uncovered_hl`

**Type:** `string`  
**Default:** `"CoverageUncovered"`

Highlight group name for uncovered lines.

```lua
uncovered_hl = "CoverageUncovered"
```

### `partial_hl`

**Type:** `string`  
**Default:** `"CoveragePartial"`

Highlight group name for partially covered lines (lines with branch coverage where some branches were taken and others weren't).

```lua
partial_hl = "CoveragePartial"
```

### Color Configuration Examples

**Example 1: Auto-adapt colors (default)**

```lua
require("crazy-coverage").setup({
  auto_adapt_colors = true,  -- Automatically match your theme
})
```

**Example 2: Disable auto-adaptation, use custom colors**

```lua
require("crazy-coverage").setup({
  auto_adapt_colors = false,
  colors = {
    covered = { bg = "#1a4d1a", fg = "#66ff66" },    -- Dark green
    uncovered = { bg = "#4d1a1a", fg = "#ff6666" },  -- Dark red
    partial = { bg = "#4d4d1a", fg = "#ffff66" },    -- Dark yellow
  },
})
```

**Example 3: Auto-adapt with manual overrides**

```lua
require("crazy-coverage").setup({
  auto_adapt_colors = true,      -- Auto-adapt based on theme
  colors = {
    covered = nil,               -- Use auto-adapted color
    uncovered = "#660000",       -- Force dark red
    partial = nil,               -- Use auto-adapted color
  },
})
```

**Example 4: Subtle colors for light themes**

```lua
require("crazy-coverage").setup({
  auto_adapt_colors = false,
  colors = {
    covered = { bg = "#e6ffe6", fg = "#006600" },    -- Very light green
    uncovered = { bg = "#ffe6e6", fg = "#660000" },  -- Very light red
    partial = { bg = "#fffacd", fg = "#666600" },    -- Light yellow
  },
})
```

**Example 5: High contrast colors for dark themes**

```lua
require("crazy-coverage").setup({
  auto_adapt_colors = false,
  colors = {
    covered = { bg = "#00ff00", fg = "#000000" },    -- Bright green
    uncovered = { bg = "#ff0000", fg = "#ffffff" },  -- Bright red
    partial = { bg = "#ffff00", fg = "#000000" },    -- Bright yellow
  },
})
```

### Default Highlight Colors

When auto-adaptation is enabled, the plugin detects your theme and uses:

**Dark themes:**
```lua
covered   = { bg = "#003300", fg = "#00FF00" }  -- Dark green bg, bright green fg
uncovered = { bg = "#330000", fg = "#FF4444" }  -- Dark red bg, bright red fg
partial   = { bg = "#332200", fg = "#FFAA00" }  -- Dark yellow bg, bright orange fg
```

**Light themes:**
```lua
covered   = { bg = "#CCFFCC", fg = "#006600" }  -- Light green bg, dark green fg
uncovered = { bg = "#FFCCCC", fg = "#CC0000" }  -- Light red bg, dark red fg
partial   = { bg = "#FFEECC", fg = "#CC6600" }  -- Light yellow bg, dark orange fg
```

These colors are automatically re-applied when the colorscheme changes.

## File Detection

### `coverage_dirs`

**Type:** `table`  
**Default:**
```lua
{
  "build/coverage",  -- Standard CMake coverage output
  "coverage",        -- Standard coverage directory
  "build",           -- Build directory root
  ".",               -- Project root
}
```

Directories to search for coverage files, relative to the project root. The plugin searches each directory in order and uses the first valid coverage file found.

**Intelligent File Detection**: The plugin doesn't just search for filenames - it verifies files by reading their content to confirm they're valid coverage files. This means coverage files can have any name and any extension, as long as the file contains valid coverage data.

**Search order example:**
1. Check `project_root/build/coverage/` - for any coverage file
2. Check `project_root/coverage/` - for any coverage file
3. Check `project_root/build/` - for any coverage file
4. Check `project_root/` - for any coverage file

**Supported Coverage Formats** (auto-detected by content):
- **LCOV**: Files containing `TN:`, `FN:`, `DA:`, or `end_of_record` markers
- **LLVM JSON**: Files containing `"version"` and `"data"` fields
- **Cobertura XML**: Files containing `<coverage>`, `<package>`, or `<class>` tags
- **GCOV**: `.gcda`, `.gcno` binary files
- **LLVM Profdata**: `.profdata` binary files

Filename doesn't matter - the plugin verifies coverage by actual content!

**Examples of auto-detected files:**
```
project_root/build/my_coverage_report         ← No extension
project_root/coverage_2025_01_09.json         ← Custom name
project_root/results.xml                       ← Non-standard name
project_root/build/cov_data                   ← No extension
```

Custom directories:

```lua
-- Add custom coverage output directory
coverage_dirs = {
  "build/coverage",      -- CMake default
  ".coverage",           -- Custom location
  "build/reports",       -- Another location
  "coverage",            -- Standard location
  ".",                   -- Project root
}
```

### `coverage_patterns`

**Type:** `table`  
**Default:**
```lua
{
  c = { "*.lcov", "coverage.json", "coverage.xml", "*.profdata" },
  cpp = { "*.lcov", "coverage.json", "coverage.xml", "*.profdata" },
}
```

**(Deprecated)** This option is kept for compatibility but is no longer strictly required. The plugin now uses intelligent content-based detection to identify coverage files, regardless of filename or extension.

The plugin will search for these patterns in the configured directories, but if a file doesn't match the pattern, it will still be checked by content inspection.

```lua
coverage_patterns = {
  c = { "*.lcov", "coverage.json" },
  cpp = { "*.lcov", "coverage.json" },
  python = { "coverage.xml", ".coverage" },
  rust = { "coverage.json", "lcov.info" },
}
```

### `project_markers`

**Type:** `table`  
**Default:** `{ ".git", "CMakeLists.txt", "Makefile", "compile_commands.json" }`

List of files/directories that indicate the project root. The plugin searches upward from the current file location until it finds one of these markers.

```lua
project_markers = {
  ".git",
  "CMakeLists.txt",
  "Makefile",
  "compile_commands.json",
  "package.json",  -- Add for JavaScript/TypeScript projects
  "Cargo.toml",    -- Add for Rust projects
}
```

## Cache Settings

### `cache_enabled`

**Type:** `boolean`  
**Default:** `true`

Enable caching of parsed coverage data to improve performance when reloading the same coverage file.

```lua
cache_enabled = true
```

### `cache_dir`

**Type:** `string`  
**Default:** `vim.fn.stdpath("cache") .. "/crazy-coverage.nvim"`

Directory where cached coverage data is stored. On most systems, this defaults to:
- Linux: `~/.cache/nvim/crazy-coverage.nvim`
- macOS: `~/Library/Caches/nvim/crazy-coverage.nvim`
- Windows: `~/AppData/Local/nvim-data/crazy-coverage.nvim`

```lua
cache_dir = vim.fn.stdpath("cache") .. "/crazy-coverage.nvim"
```

### `auto_load`

**Type:** `boolean`  
**Default:** `true`

**Deprecated:** This option is deprecated in favor of using `:CoverageToggle` which provides smarter auto-loading with file watching.

When `true`, attempts to auto-load coverage when opening a file. However, it's recommended to use `:CoverageToggle` instead, which provides:
- Explicit control over when coverage is loaded
- File watching for automatic reloading
- Cleaner resource management

```lua
auto_load = true  -- Deprecated: use :CoverageToggle instead
```

## Complete Example

Here's a complete configuration with all options specified:

```lua
require("crazy-coverage").setup({
  -- Display
  virt_text_pos = "eol",
  default_show_hit_count = true,
  show_hit_count = true,
  show_percentage = false,
  show_branch_summary = true,
  enable_line_hl = true,
  
  -- Colors
  auto_adapt_colors = true,
  colors = {
    covered = nil,
    uncovered = nil,
    partial = nil,
  },
  covered_hl = "CoverageCovered",
  uncovered_hl = "CoverageUncovered",
  partial_hl = "CoveragePartial",
  
  -- File detection
  coverage_dirs = {
    "build/coverage",
    "coverage",
    "build",
    ".",
  },
  coverage_patterns = {
    c = { "*.lcov", "coverage.json", "coverage.xml", "*.profdata" },
    cpp = { "*.lcov", "coverage.json", "coverage.xml", "*.profdata" },
  },
  project_markers = { ".git", "CMakeLists.txt", "Makefile", "compile_commands.json" },
  
  -- Cache
  cache_enabled = true,
  cache_dir = vim.fn.stdpath("cache") .. "/crazy-coverage.nvim",
  
  -- Deprecated
  auto_load = true,  -- Use :CoverageToggle instead
})
```

## Common Configurations

### Minimal (All Defaults)

```lua
require("crazy-coverage").setup()
```

### Inline with Branch Coverage

```lua
require("crazy-coverage").setup({
  virt_text_pos = "inline",
  show_branch_summary = true,
})
```

### Right-Aligned, No Hit Counts

```lua
require("crazy-coverage").setup({
  virt_text_pos = "right_align",
  default_show_hit_count = false,
})
```

### Custom Coverage Search Directories

```lua
require("crazy-coverage").setup({
  coverage_dirs = {
    "build/coverage",    -- CMake default
    ".coverage",         -- Custom location
    "coverage-reports",  -- Another location
    ".",                 -- Project root fallback
  },
})
```

### Custom Colors (Dark Theme)

```lua
-- Define custom highlights
vim.api.nvim_set_hl(0, "DarkCovered", { bg = "#003300", fg = "#00DD00" })
vim.api.nvim_set_hl(0, "DarkUncovered", { bg = "#330000", fg = "#DD0000" })
vim.api.nvim_set_hl(0, "DarkPartial", { bg = "#333300", fg = "#DDDD00" })

require("crazy-coverage").setup({
  covered_hl = "DarkCovered",
  uncovered_hl = "DarkUncovered",
  partial_hl = "DarkPartial",
})
```

### Overlay with Percentage

```lua
require("crazy-coverage").setup({
  virt_text_pos = "overlay",
  show_hit_count = true,
  show_percentage = true,
})
```

## See Also

- [Usage Guide](usage.md) - Commands and keybindings
- [Supported Formats](formats.md) - Coverage file formats
- [README](../README.md) - Main documentation
