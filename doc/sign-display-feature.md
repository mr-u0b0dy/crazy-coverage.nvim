# Sign Column and Line Number Display Feature

This feature adds the ability to display coverage hit counts near line numbers in two ways:

## Display Modes

### 1. Sign Column Display (`show_hit_count_in_sign`)
Shows hit counts in the sign column (left gutter) next to line numbers.
- **Default**: `false` (disabled)
- **Note**: Sign column is shared with git-signs, diagnostics, and debugger
- **Tip**: Use `set signcolumn=auto:2` to show multiple signs simultaneously

### 2. Line Number Highlighting (`highlight_line_numbers`)
Colorizes line numbers based on coverage status (covered/uncovered/partial).
- **Default**: `true` (enabled)
- **Requires**: `:set number` to be enabled in Neovim

## Configuration

```lua
require("crazy-coverage").setup({
  -- Show hit count in sign column (e.g., "3" or "9+")
  show_hit_count_in_sign = false,
  
  -- Highlight line numbers based on coverage
  highlight_line_numbers = true,
  
  -- Custom format for sign text (max 2 chars recommended)
  sign_text_format = function(hit_count)
    if hit_count >= 10 then
      return "9+"
    end
    return tostring(hit_count)
  end,
})
```

## Commands

- `:CoverageToggleSign` - Toggle hit count display in sign column
- `:CoverageToggleLineNumbers` - Toggle line number highlighting
- `:CoverageToggleHitCount` - Toggle end-of-line virtual text (existing feature)

## Usage Examples

### Example 1: Sign Column Only
```lua
require("crazy-coverage").setup({
  show_hit_count = false,           -- Disable end-of-line display
  show_hit_count_in_sign = true,    -- Enable sign column
  highlight_line_numbers = true,     -- Enable line number colors
  enable_line_hl = false,            -- Disable line highlighting
})
```

### Example 2: All Display Modes
```lua
require("crazy-coverage").setup({
  show_hit_count = true,             -- End-of-line virtual text
  show_hit_count_in_sign = true,     -- Sign column
  highlight_line_numbers = true,     -- Line number colors
  enable_line_hl = true,             -- Full line highlighting
})
```

### Example 3: Custom Sign Format
```lua
require("crazy-coverage").setup({
  show_hit_count_in_sign = true,
  sign_text_format = function(hit_count)
    if hit_count >= 100 then
      return "∞"  -- Infinity symbol for very high counts
    elseif hit_count >= 10 then
      return "+"
    end
    return tostring(hit_count)
  end,
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
