# Usage Guide

Complete guide to using crazy-coverage.nvim for viewing and navigating code coverage in Neovim.

## Table of Contents

- [Commands](#commands)
- [Smart Toggle Workflow](#smart-toggle-workflow)
- [Navigation](#navigation)
- [Keybindings](#keybindings)
- [Common Workflows](#common-workflows)
- [Display Modes](#display-modes)

---

## Commands

### Coverage Management

| Command | Description |
|---------|-------------|
| `:CoverageToggle` | **Smart toggle**: Auto-loads coverage, enables overlay, watches for changes |
| `:CoverageLoad <file>` | Manually load specific coverage file |
| `:CoverageToggleHitCount` | Toggle hit count display on/off |

### Navigation Commands

| Command | Description |
|---------|-------------|
| `:CoverageNextCovered` | Jump to next covered line |
| `:CoveragePrevCovered` | Jump to previous covered line |
| `:CoverageNextPartial` | Jump to next partially covered line (branches) |
| `:CoveragePrevPartial` | Jump to previous partially covered line |
| `:CoverageNextUncovered` | Jump to next uncovered line |
| `:CoveragePrevUncovered` | Jump to previous uncovered line |

---

## Smart Toggle Workflow

The `:CoverageToggle` command provides a complete coverage management solution:

### Automatic Coverage File Discovery

When you run `:CoverageToggle`, the plugin automatically:

1. **Finds project root** - Searches upward for `.git`, `CMakeLists.txt`, `Makefile`, etc.
2. **Searches standard directories** - Looks in `build/coverage/`, `coverage/`, `build/`, and project root
3. **Detects format by content** - Identifies LCOV, JSON, XML files regardless of name
4. **Returns first match** - Uses the first valid coverage file found

**You don't need to specify a file!** Unless your coverage file is in a non-standard location, it will be found automatically.

See [File Discovery](file-discovery.md) for details on configuration and custom search paths.

### When Enabled

1. **Auto-detects** coverage file in standard directories
2. **Loads** coverage data automatically  
3. **Displays** overlay with line highlighting
4. **Shows** hit counts (if `default_show_hit_count = true`)
5. **Watches** coverage file for changes (polls every 2 seconds)
6. **Auto-reloads** when coverage file updates
7. **Notifies** you when coverage is refreshed

### When Disabled

1. **Clears** all overlays and highlights
2. **Stops** file watching
3. **Releases** all resources

### Example

```vim
" Open a source file
:e src/math_utils.c

" Enable coverage (auto-finds and loads file!)
:CoverageToggle

" Work on your code, run tests in another terminal:
" $ make test && make lcov

" Coverage automatically reloads when file changes!
" You'll see a notification: "Coverage reloaded"

" When done, disable everything:
:CoverageToggle
```

---

## Navigation

Navigate through coverage using Vim-style motions: `{` or `}` for direction, then `c` as the coverage prefix, then `c/p/u` for the target.

### Keybindings

| Keys | Command | Description |
|------|---------|-------------|
| `]cc` | `:CoverageNextCovered` | Next covered line |
| `[cc` | `:CoveragePrevCovered` | Previous covered line |
| `]cp` | `:CoverageNextPartial` | Next partial line |
| `[cp` | `:CoveragePrevPartial` | Previous partial line |
| `]cu` | `:CoverageNextUncovered` | Next uncovered line |
| `[cu` | `:CoveragePrevUncovered` | Previous uncovered line |

### Navigation Tips

**Find Untested Code**
```vim
" Jump through all uncovered lines
]cu   " Next uncovered
]cu   " Next uncovered again
[cu   " Go back to previous uncovered
```

**Review Branch Coverage**
```vim
" Jump through partially covered lines (missed branches)
]cp   " Next partial
]cp   " Next partial again
```

**Quick Coverage Check**
```vim
" Jump to first uncovered line
gg    " Go to top of file
]cu   " Jump to first uncovered line
```

---

## Keybindings

### Recommended Setup (AstroVim/lazy.nvim)

```lua
keys = {
  -- Main commands
  { "<leader>ct", "<cmd>CoverageToggle<cr>", desc = "Coverage: Toggle" },
  { "<leader>ch", "<cmd>CoverageToggleHitCount<cr>", desc = "Coverage: Toggle Hit Count" },
  
  -- Navigate covered lines
  { "]cc", "<cmd>CoverageNextCovered<cr>", desc = "Coverage: Next Covered" },
  { "[cc", "<cmd>CoveragePrevCovered<cr>", desc = "Coverage: Prev Covered" },
  
  -- Navigate partial lines
  { "]cp", "<cmd>CoverageNextPartial<cr>", desc = "Coverage: Next Partial" },
  { "[cp", "<cmd>CoveragePrevPartial<cr>", desc = "Coverage: Prev Partial" },
  
  -- Navigate uncovered lines
  { "]cu", "<cmd>CoverageNextUncovered<cr>", desc = "Coverage: Next Uncovered" },
  { "[cu", "<cmd>CoveragePrevUncovered<cr>", desc = "Coverage: Prev Uncovered" },
}
```

### Minimal Setup

```lua
keys = {
  { "<leader>ct", "<cmd>CoverageToggle<cr>", desc = "Coverage: Toggle" },
  { "]cu", "<cmd>CoverageNextUncovered<cr>", desc = "Next Uncovered" },
  { "[cu", "<cmd>CoveragePrevUncovered<cr>", desc = "Prev Uncovered" },
}
```

### Manual vim.keymap Setup

```lua
local function map(mode, lhs, rhs, desc)
  vim.keymap.set(mode, lhs, rhs, { desc = desc, silent = true })
end

map("n", "<leader>ct", "<cmd>CoverageToggle<cr>", "Coverage: Toggle")
map("n", "<leader>ch", "<cmd>CoverageToggleHitCount<cr>", "Coverage: Toggle Hit Count")
map("n", "]cu", "<cmd>CoverageNextUncovered<cr>", "Coverage: Next Uncovered")
map("n", "[cu", "<cmd>CoveragePrevUncovered<cr>", "Coverage: Prev Uncovered")
map("n", "]cp", "<cmd>CoverageNextPartial<cr>", "Coverage: Next Partial")
map("n", "[cp", "<cmd>CoveragePrevPartial<cr>", "Coverage: Prev Partial")
map("n", "]cc", "<cmd>CoverageNextCovered<cr>", "Coverage: Next Covered")
map("n", "[cc", "<cmd>CoveragePrevCovered<cr>", "Coverage: Prev Covered")
```

---

## Common Workflows

### Workflow 1: Test-Driven Development

```vim
" 1. Write a new function
:e src/new_feature.c

" 2. Enable coverage
:CoverageToggle

" 3. All lines show as uncovered (red)

" 4. Write and run tests in terminal
" $ make test && make lcov

" 5. Coverage auto-reloads, lines turn green/orange

" 6. Jump to uncovered lines
}cu

" 7. Add more tests, coverage auto-updates
```

### Workflow 2: Code Review

```vim
" 1. Checkout PR branch
" $ git checkout pr/feature-branch

" 2. Generate coverage
" $ make test && make lcov

" 3. Open files and enable coverage
:e src/feature.c
:CoverageToggle

" 4. Review uncovered code
}cu   " Jump to uncovered lines
" Check if uncovered code needs tests

" 5. Review partial coverage (missed branches)
}cp   " Jump to partial lines
" Check if all edge cases are tested
```

### Workflow 3: Refactoring

```vim
" 1. Load coverage before refactoring
:e src/legacy.c
:CoverageToggle

" 2. See which lines are tested (green)

" 3. Refactor only tested code
" (or add tests first if needed)

" 4. Re-run tests
" $ make test && make lcov

" 5. Coverage auto-reloads
" Ensure coverage didn't decrease
```

---

## Display Modes

### Virtual Text Position

Control where coverage info appears:

```lua
-- End of line (default)
require("crazy-coverage").setup({
  virt_text_pos = "eol",
})
-- Example: print("hello");    |-- 5

-- Inline (after code)
require("crazy-coverage").setup({
  virt_text_pos = "inline",
})
-- Example: print("hello");  5

-- Right aligned
require("crazy-coverage").setup({
  virt_text_pos = "right_align",
})
-- Example: print("hello");                  5

-- Overlay (replaces line)
require("crazy-coverage").setup({
  virt_text_pos = "overlay",
})
-- Example: (line is replaced with coverage info)
```

### Hit Count Display

Toggle hit counts on/off:

```vim
" Enable hit counts
:CoverageToggleHitCount
" Lines show:  5  (executed 5 times)

" Disable hit counts
:CoverageToggleHitCount
" Lines show only color highlighting
```

### Branch Coverage

Show branch coverage per line:

```lua
require("crazy-coverage").setup({
  show_branch_summary = true,
})
```

Display format: `5 b:2/4`
- `5` = hit count (line executed 5 times)
- `b:2/4` = 2 out of 4 branches taken

### Line Highlighting

Coverage status shown via background colors:

| Color | Status | Meaning |
|-------|--------|---------|
| Green | Covered | Line fully executed, all branches taken |
| Orange | Partial | Line executed, but some branches not taken |
| Red | Uncovered | Line never executed |

Customize colors:

```lua
-- Define custom highlights before setup
vim.api.nvim_set_hl(0, "CoverageCovered", { bg = "#004400" })
vim.api.nvim_set_hl(0, "CoverageUncovered", { bg = "#440000" })
vim.api.nvim_set_hl(0, "CoveragePartial", { bg = "#444400" })

require("crazy-coverage").setup()
```

---

## Next Steps

- See [Configuration Reference](configuration.md) for all 15+ config options
- See [Coverage Examples](../coverage-examples/) for C/C++ examples
- See [Supported Formats](formats.md) for coverage generation details
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
