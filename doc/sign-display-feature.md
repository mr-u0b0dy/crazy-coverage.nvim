# Sign Column and Line Number Display Feature

This document covers the legacy hit-count sign display and the newer coverage-status sign-column mode.

## Display Modes

### 1. Coverage Status in Sign Column (`show_coverage_in_sign_column`)

Shows coverage status in the sign column and keeps hit-count display controlled separately by `hit_count.display`.

- **Default**: `false` (disabled)
- **Behavior**: Replaces in-buffer coverage line highlighting with sign-column coverage markers
- **Hit counts**: Still shown using the existing hit-count display settings

```lua
require("crazy-coverage").setup({
  show_coverage_in_sign_column = true,
  hit_count = {
    display = "eol",
  },
})
```

### 2. Legacy Hit Count Sign Display (`hit_count.display = "sign"`)

Shows hit counts in the sign column (left gutter) next to line numbers.

- **Default**: `eol` for the built-in configuration
- **Note**: Sign column is shared with git-signs, diagnostics, and debugger
- **Tip**: Use `set signcolumn=auto:2` to show multiple signs simultaneously

### 3. Coverage Line Highlighting (`enable_line_hl`)

Highlights coverage status in the buffer (covered/uncovered/partial) using line background colors.

- **Default**: `true` (enabled)

```lua
enable_line_hl = true
```

## Configuration

```lua
require("crazy-coverage").setup({
  -- Show coverage status in the sign column instead of in-buffer line highlighting
  show_coverage_in_sign_column = false,

  -- Show hit counts in the sign column (e.g., "3" or "9+")
  hit_count = {
    display = "eol",
    sign_text_format = function(hit_count)
      if hit_count >= 10 then
        return "9+"
      end
      return tostring(hit_count)
    end,
  },

  -- Keep in-buffer coverage highlights if you do not want sign-only coverage
  enable_line_hl = true,
})
```

## Commands

- `:CoverageToggleSignColumn` - Toggle coverage status in the sign column
- `:CoverageToggleHitCount` - Toggle end-of-line virtual text (existing feature)

## Usage Examples

### Example 1: Sign Column Only

```lua
require("crazy-coverage").setup({
  show_coverage_in_sign_column = true, -- Coverage markers in the gutter
  hit_count = {
    display = "eol",                -- Keep hit counts in the buffer
  },
  enable_line_hl = false,            -- Disable coverage line highlighting
})
```

### Example 2: All Display Modes

```lua
require("crazy-coverage").setup({
  show_coverage_in_sign_column = true, -- Coverage markers in the gutter
  hit_count = {
    display = "sign",               -- Hit counts in the sign column too
  },
  enable_line_hl = false,             -- Coverage line highlighting disabled in sign mode
})
```

### Example 3: Custom Sign Format

```lua
require("crazy-coverage").setup({
  hit_count = {
    display = "sign",
    sign_text_format = function(hit_count)
      if hit_count >= 100 then
        return "∞"  -- Infinity symbol for very high counts
      elseif hit_count >= 10 then
        return "+"
      end
      return tostring(hit_count)
    end,
  },
})
```

## Visual Examples

With all features enabled, your code might look like:

```
Sign│ Ln │ Code
────┼────┼───────────────────────────────
  3 │  5 │ int add(int a, int b) {      3
  3 │  6 │   return a + b;              3
  3 │  7 │ }                             3
    │  8 │
  0 │  9 │ int unused_function() {      0
  0 │ 10 │   return 42;                 0
  0 │ 11 │ }                             0
```

- Sign column (left): Shows hit count (3, 0)
- Line numbers: Colored green (covered) or red (uncovered)
- End of line: Virtual text showing hit count

## Testing

Run the demo script to see the feature in action:

```bash
./test/demo_sign_display.sh
```

Or manually:

```bash
nvim -u test/test_sign_display.lua
```

## Limitations

1. **Sign column width**: Limited to 1-2 characters typically
2. **Sign column conflicts**: May conflict with other plugins using signs (git-signs, diagnostics)
3. **Line number display**: Requires `:set number` to be enabled
4. **Cannot replace line numbers**: Neovim's extmark API can only colorize line numbers, not replace them with custom text

## Workarounds

### For Sign Column Conflicts

Enable multiple sign columns:

```vim
set signcolumn=auto:2
```

### For High Hit Counts

Use the `sign_text_format` function to abbreviate large numbers:

```lua
sign_text_format = function(hit_count)
  if hit_count >= 1000 then return "K" end
  if hit_count >= 100 then return "+" end
  if hit_count >= 10 then return "9+" end
  return tostring(hit_count)
end
```
