# Usage Guide

## Commands

### Loading Coverage

- `:CoverageLoad [file]` - Load coverage from a file (auto-detects format)
  - If no file specified, searches project root for common coverage files
  - Supports: `.lcov`, `.info`, `.json`, `.xml`, `.gcda`, `.gcno`, `.profdata`

- `:CoverageAutoLoad` - Auto-load coverage file for current buffer

### Controlling Display

- `:CoverageToggle` - Toggle coverage overlay on/off
- `:CoverageEnable` - Enable coverage overlay
- `:CoverageDisable` - Disable coverage overlay
- `:CoverageClear` - Clear all coverage data

## Configuration

### Basic Setup

```lua
require("crazy-coverage").setup({
  -- Virtual text position
  virt_text_pos = "eol",           -- "eol", "inline", "overlay", "right_align"
  
  -- Display options
  show_hit_count = true,            -- Show execution count
  show_percentage = false,          -- Show percentage instead of count
  show_branch_summary = false,      -- Show per-line branch summary (b:taken/total)
  
  -- Auto-loading
  auto_load = true,                 -- Auto-load coverage on file open
  
  -- Highlight groups
  covered_hl = "CoverageCovered",   -- Covered lines
  uncovered_hl = "CoverageUncovered", -- Uncovered lines
  partial_hl = "CoveragePartial",   -- Partially covered (branches)
})
```

### Custom Highlight Colors

```lua
-- Set up plugin first
require("crazy-coverage").setup()

-- Then customize colors
vim.api.nvim_set_hl(0, "CoverageCovered", { 
  fg = "#00ff00", 
  bold = true 
})

vim.api.nvim_set_hl(0, "CoverageUncovered", { 
  fg = "#ff0000" 
})

vim.api.nvim_set_hl(0, "CoveragePartial", { 
  fg = "#ffaa00" 
})
```

### Key Mappings

```lua
-- Example key mappings
vim.keymap.set("n", "<leader>cl", "<cmd>CoverageLoad<CR>", { desc = "Load coverage" })
vim.keymap.set("n", "<leader>ct", "<cmd>CoverageToggle<CR>", { desc = "Toggle coverage" })
vim.keymap.set("n", "<leader>cc", "<cmd>CoverageClear<CR>", { desc = "Clear coverage" })
```

## Examples

### Example 1: Basic Usage

```lua
-- Load and view coverage
:CoverageLoad coverage.lcov
-- Coverage overlay appears with hit counts

-- Toggle off
:CoverageToggle

-- Toggle back on
:CoverageToggle
```

### Example 2: With Branch Coverage

```lua
require("crazy-coverage").setup({
  show_hit_count = true,
  show_branch_summary = true,  -- Enable branch display
})

-- Load coverage with branch data
:CoverageLoad coverage.lcov
-- See: "5 b:1/2" (5 hits, 1 of 2 branches taken)
```

### Example 3: Auto-loading

```lua
require("crazy-coverage").setup({
  auto_load = true,
  coverage_patterns = {
    c = { "*.lcov", "coverage.json" },
    cpp = { "*.lcov", "coverage.json" },
  },
  project_markers = { ".git", "CMakeLists.txt" },
})

-- Coverage auto-loads when opening a file
:edit src/main.c
-- Plugin searches for coverage files automatically
```

### Example 4: Using with lazy.nvim

```lua
{
  "mr-u0b0dy/crazy-coverage.nvim",
  config = function()
    require("crazy-coverage").setup({
      virt_text_pos = "eol",
      show_hit_count = true,
      show_branch_summary = true,
    })
    
    -- Set custom keymaps
    vim.keymap.set("n", "<leader>cl", "<cmd>CoverageLoad<CR>")
    vim.keymap.set("n", "<leader>ct", "<cmd>CoverageToggle<CR>")
  end,
}
```

## Workflow Integration

### CI/CD Integration

After your CI generates coverage files, load them locally:

```bash
# Download coverage artifact from CI
curl https://ci.example.com/coverage.lcov -o coverage.lcov

# Open Neovim and load coverage
nvim src/main.c
:CoverageLoad coverage.lcov
```

### Development Workflow

1. Run tests with coverage:
   ```bash
   # GCC example
   gcc -fprofile-arcs -ftest-coverage -o test test.c
   ./test
   lcov --directory . --capture --output-file coverage.lcov
   ```

2. Open files in Neovim:
   ```bash
   nvim src/main.c
   ```

3. Load coverage:
   ```vim
   :CoverageLoad coverage.lcov
   ```

4. Identify uncovered lines (shown in red)

5. Write tests for uncovered code

6. Regenerate coverage and reload:
   ```vim
   :CoverageLoad coverage.lcov
   ```
