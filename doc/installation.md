# Installation Guide

Complete installation instructions for crazy-coverage.nvim across different plugin managers and configurations.

## Table of Contents

- [Plugin Managers](#plugin-managers)
  - [lazy.nvim](#lazynvim)
  - [packer.nvim](#packernvim)
  - [vim-plug](#vim-plug)
- [AstroVim Setup](#astrovim-setup)
- [Development Installation](#development-installation)
- [Requirements](#requirements)
- [Verification](#verification)

---

## Plugin Managers

### lazy.nvim

**Basic Installation**

```lua
{
  "mr-u0b0dy/crazy-coverage.nvim",
  config = function()
    require("crazy-coverage").setup()
  end,
}
```

**With Custom Configuration**

```lua
{
  "mr-u0b0dy/crazy-coverage.nvim",
  opts = {
    virt_text_pos = "right_align",
    default_show_hit_count = true,
    show_branch_summary = true,
  },
}
```

**With Keybindings**

```lua
{
  "mr-u0b0dy/crazy-coverage.nvim",
  keys = {
    { "<leader>ct", "<cmd>CoverageToggle<cr>", desc = "Coverage: Toggle" },
    { "<leader>ch", "<cmd>CoverageToggleHitCount<cr>", desc = "Coverage: Toggle Hit Count" },
    { "}u", "<cmd>CoverageNextUncovered<cr>", desc = "Coverage: Next Uncovered" },
    { "{u", "<cmd>CoveragePrevUncovered<cr>", desc = "Coverage: Prev Uncovered" },
  },
  config = function()
    require("crazy-coverage").setup()
  end,
}
```

---

### packer.nvim

**Basic Installation**

```lua
use {
  "mr-u0b0dy/crazy-coverage.nvim",
  config = function()
    require("crazy-coverage").setup()
  end,
}
```

**With Custom Configuration**

```lua
use {
  "mr-u0b0dy/crazy-coverage.nvim",
  config = function()
    require("crazy-coverage").setup({
      virt_text_pos = "eol",
      default_show_hit_count = true,
    })
  end,
}
```

---

### vim-plug

**Installation**

Add to your `init.vim` or `.vimrc`:

```vim
Plug 'mr-u0b0dy/crazy-coverage.nvim'
```

Then run:
```vim
:PlugInstall
```

**Configuration**

Add to your Lua config or `init.lua`:

```lua
require("crazy-coverage").setup({
  virt_text_pos = "eol",
  default_show_hit_count = true,
})
```

Or in Vimscript:

```vim
lua << EOF
require("crazy-coverage").setup({
  virt_text_pos = "eol",
  default_show_hit_count = true,
})
EOF
```

---

## AstroVim Setup

AstroVim uses lazy.nvim under the hood. Place the configuration in `~/.config/nvim/lua/plugins/crazy-coverage.lua`.

**Complete AstroVim Configuration Example**

```lua
-- File: ~/.config/nvim/lua/plugins/crazy-coverage.lua

return {
  "mr-u0b0dy/crazy-coverage.nvim",
  
  -- Optional: Use local development version
  -- dev = true,
  -- dir = "/home/your-username/crazy-coverage.nvim",
  
  keys = {
    -- Main commands
    { "<leader>ct", "<cmd>CoverageToggle<cr>", desc = "Coverage: Toggle (Auto-load + Watch)" },
    { "<leader>ch", "<cmd>CoverageToggleHitCount<cr>", desc = "Coverage: Toggle Hit Count" },
    
    -- Navigation: Covered lines
    { "}c", "<cmd>CoverageNextCovered<cr>", desc = "Coverage: Next Covered Line" },
    { "{c", "<cmd>CoveragePrevCovered<cr>", desc = "Coverage: Prev Covered Line" },
    
    -- Navigation: Partially covered lines
    { "}p", "<cmd>CoverageNextPartial<cr>", desc = "Coverage: Next Partial Line" },
    { "{p", "<cmd>CoveragePrevPartial<cr>", desc = "Coverage: Prev Partial Line" },
    
    -- Navigation: Uncovered lines
    { "}u", "<cmd>CoverageNextUncovered<cr>", desc = "Coverage: Next Uncovered Line" },
    { "{u", "<cmd>CoveragePrevUncovered<cr>", desc = "Coverage: Prev Uncovered Line" },
  },
  
  opts = {
    virt_text_pos = "right_align",
    default_show_hit_count = true,
    show_branch_summary = true,
    enable_line_hl = true,
  },
}
```

**Minimal AstroVim Configuration**

```lua
-- File: ~/.config/nvim/lua/plugins/crazy-coverage.lua

return {
  "mr-u0b0dy/crazy-coverage.nvim",
  keys = {
    { "<leader>ct", "<cmd>CoverageToggle<cr>", desc = "Coverage: Toggle" },
    { "}u", "<cmd>CoverageNextUncovered<cr>", desc = "Coverage: Next Uncovered" },
    { "{u", "<cmd>CoveragePrevUncovered<cr>", desc = "Coverage: Prev Uncovered" },
  },
}
```

---

## Development Installation

For plugin development or local testing:

**lazy.nvim with Local Directory**

```lua
{
  "mr-u0b0dy/crazy-coverage.nvim",
  dev = true,
  dir = "/home/your-username/crazy-coverage.nvim",
  config = function()
    require("crazy-coverage").setup()
  end,
}
```

**Clone the Repository**

```bash
git clone https://github.com/mr-u0b0dy/crazy-coverage.nvim.git
cd crazy-coverage.nvim
```

**Configure lazy.nvim Dev Path**

In your Neovim config:

```lua
require("lazy").setup({
  dev = {
    path = "~/projects",  -- Or wherever you cloned the repo
  },
})
```

---

## Requirements

### Required

- **Neovim 0.7+** - Plugin uses virtual text APIs from Neovim 0.7

### Optional

Coverage generation tools (choose based on your toolchain):

- **GCC/GNU Toolchain**:
  - `gcc` with `--coverage` flag
  - `lcov` for LCOV format generation
  
- **LLVM Toolchain**:
  - `clang` with `-fprofile-instr-generate -fcoverage-mapping`
  - `llvm-profdata` for profdata merging
  - `llvm-cov` for JSON export

- **Language Support**:
  - C/C++ (via GCC or LLVM)
  - Any language that generates LCOV, Cobertura XML, or LLVM JSON

---

## Verification

After installation, verify the plugin is loaded:

### Check Plugin Status

```vim
:Lazy
" Search for "crazy-coverage" and ensure it's loaded
```

### Test Basic Commands

```vim
" Should not error (may show notification if no coverage file found)
:CoverageToggle

" Should list all available commands
:Coverage<Tab>
```

### Run Example Project

```bash
cd ~/.local/share/nvim/lazy/crazy-coverage.nvim/coverage-examples/c
make lcov
```

Then in Neovim:

```vim
:e main.c
:CoverageLoad build/coverage/coverage.lcov
```

You should see coverage overlays on the lines.

---

## Troubleshooting

### Plugin Not Found

- **lazy.nvim**: Run `:Lazy sync` to install plugins
- **packer.nvim**: Run `:PackerSync`
- **vim-plug**: Run `:PlugInstall`

### Commands Not Available

Check that `setup()` was called:

```lua
-- Should be in your config somewhere
require("crazy-coverage").setup()
```

### No Coverage Displayed

1. Verify coverage file exists and is in supported format
2. Check file path with `:CoverageLoad /full/path/to/coverage.lcov`
3. Enable verbose mode: `:set verbose=1` and retry

---

## Next Steps

- See [Usage Guide](usage.md) for commands and workflows
- See [Configuration Reference](configuration.md) for customization options
- Try the [Coverage Examples](../coverage-examples/) to generate sample coverage

