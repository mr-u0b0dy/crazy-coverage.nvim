# AstroVim Configuration Example

This directory contains example configurations for integrating crazy-coverage.nvim with AstroVim.

## Installation

Copy `astrovim-config.lua` to your AstroVim configuration:

```bash
cp configs/astrovim-config.lua ~/.config/nvim/lua/plugins/crazy-coverage.lua
```

Or for local development:

```bash
# Create the file with local path
cat > ~/.config/nvim/lua/plugins/crazy-coverage.lua << 'EOF'
---@type LazySpec
return {
  {
    "mr-u0b0dy/crazy-coverage.nvim",
    dev = true,
    dir = "/path/to/your/crazy-coverage.nvim",  -- Update this path
    lazy = false,
    config = function()
      require("crazy-coverage").setup()
    end,
    keys = {
      -- See astrovim-config.lua for full keybinding examples
    },
  },
}
EOF
```

## Keybindings

The example configuration includes the following keybindings:

### Coverage Management (`<leader>l` prefix)
- `<leader>ll` - Load coverage file
- `<leader>lt` - Toggle coverage overlay
- `<leader>le` - Enable coverage overlay
- `<leader>ld` - Disable coverage overlay
- `<leader>lc` - Clear coverage data
- `<leader>la` - Auto-load coverage

### Navigation
- `}cc` / `{cc` - Next/Previous covered line
- `}cp` / `{cp` - Next/Previous partially covered line
- `}cu` / `{cu` - Next/Previous uncovered line

## Customization

You can customize the configuration in the `setup()` function:

```lua
require("crazy-coverage").setup({
  virt_text_pos = "eol",           -- Position: "eol", "inline", "overlay", "right_align"
  show_hit_count = true,            -- Show execution count
  show_branch_summary = false,      -- Show branch coverage (b:taken/total)
  auto_load = true,                 -- Auto-load coverage on file open
  enable_line_hl = false,           -- Enable full line highlighting
})
```

## Usage

After restarting Neovim or running `:Lazy sync`:

1. Generate coverage data for your project
2. Open a source file
3. Load coverage: `<leader>ll` and enter the coverage file path
4. Navigate uncovered code: `}cu` to find lines that need tests
5. Toggle overlay: `<leader>lt` to hide/show coverage

## Supported Coverage Formats

- LCOV (`.lcov`, `.info`)
- Cobertura XML (`.xml`)
- LLVM JSON (`.json`)
- GCOV (`.gcov`)
- LLVM Profdata (requires conversion with `llvm-profdata` and `llvm-cov`)

See the main [README](../README.md) and [documentation](../doc/) for more details.
