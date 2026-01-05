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

### `covered_hl`

**Type:** `string`  
**Default:** `"CoverageCovered"`

Highlight group name for covered lines. By default, this is set to green background.

You can customize the appearance by defining your own highlight:

```lua
vim.api.nvim_set_hl(0, "MyCovered", { bg = "#004400", fg = "#00FF00" })

require("crazy-coverage").setup({
  covered_hl = "MyCovered"
})
```

### `uncovered_hl`

**Type:** `string`  
**Default:** `"CoverageUncovered"`

Highlight group name for uncovered lines. By default, this is set to red background.

```lua
covered_hl = "CoverageUncovered"
```

### `partial_hl`

**Type:** `string`  
**Default:** `"CoveragePartial"`

Highlight group name for partially covered lines (lines with branch coverage where some branches were taken and others weren't). By default, this is set to orange background.

```lua
partial_hl = "CoveragePartial"
```

### Default Highlight Colors

The plugin defines these default colors:

```lua
-- Covered lines (green)
CoverageCovered = { bg = "#00AA00", fg = "NONE", bold = true }

-- Uncovered lines (red)
CoverageUncovered = { bg = "#FF0000", fg = "NONE", bold = true }

-- Partially covered lines (orange)
CoveragePartial = { bg = "#FFAA00", fg = "NONE", bold = true }
```

These are re-applied when the colorscheme changes.

## File Detection

### `coverage_patterns`

**Type:** `table`  
**Default:**
```lua
{
  c = { "*.lcov", "coverage.json", "coverage.xml", "*.profdata" },
  cpp = { "*.lcov", "coverage.json", "coverage.xml", "*.profdata" },
}
```

File patterns to search for when auto-detecting coverage files. The plugin will search for these patterns in the project root directory.

You can add support for other languages:

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
  
  -- Highlight groups
  covered_hl = "CoverageCovered",
  uncovered_hl = "CoverageUncovered",
  partial_hl = "CoveragePartial",
  
  -- File detection
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
