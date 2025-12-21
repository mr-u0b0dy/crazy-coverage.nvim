# Architecture

## Overview

crazy-coverage.nvim uses a modular, two-layer architecture:

1. **Parser/Converter Layer** - Reads coverage files and converts to normalized format
2. **Renderer Layer** - Displays coverage using Neovim extmarks API

```
┌─────────────────┐
│ Coverage Files  │
│ .lcov .json .xml│
│ .gcda .profdata │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│ Format Detector │  (utils.detect_format)
└────────┬────────┘
         │
         ▼
    ┌────┴────┐
    │ Parser  │  Converter (if binary)
    └────┬────┘
         │
         ▼
┌─────────────────┐
│ Normalized Data │  CoverageData model
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│    Renderer     │  Extmarks + Virtual text
└─────────────────┘
```

## Directory Structure

```
lua/crazy-coverage/
├── init.lua                # Main API and command setup
├── config.lua              # Configuration and defaults
├── utils.lua               # Format detection, file I/O
├── renderer.lua            # Extmark rendering engine
├── parser/
│   ├── init.lua            # Parser dispatcher
│   ├── lcov.lua            # LCOV parser
│   ├── llvm_json.lua       # LLVM JSON parser
│   └── cobertura.lua       # Cobertura XML parser
└── converter/
    ├── gcov.lua            # GCOV converter
    └── llvm_profdata.lua   # LLVM Profdata converter
```
└── converter/
    ├── gcov.lua            # GCOV → LCOV converter
    └── llvm_profdata.lua   # Profdata → JSON converter
```

## Data Model

All parsers output a normalized `CoverageData` structure:

```lua
{
  files = {
    {
      path = "src/main.c",           -- Absolute or relative file path
      lines = {
        {
          line_num = 10,               -- Line number (1-indexed)
          hit_count = 5,               -- Execution count
          covered = true               -- true if hit_count > 0
        },
        -- ... more lines
      },
      branches = {
        {
          line = 10,                   -- Line number
          id = 0,                      -- Branch ID
          hit_count = 3                -- Branch execution count
        },
        -- ... more branches
      },
      functions = {                    -- Optional (LCOV only)
        {
          name = "my_func",            -- Function name
          line = 10,                   -- Function start line
          hit_count = 5,               -- Call count
          covered = true               -- true if called
        },
        -- ... more functions
      }
    },
    -- ... more files
  }
}
```

## Parser Layer

### Parser Interface

Each parser implements:

```lua
function M.parse(file_path)
  -- Returns: CoverageData table or nil on error
end
```

### Parser Dispatcher

`lua/coverage/parser/init.lua` routes to the appropriate parser:

```lua
local M = {}

M.parsers = {
  lcov = require("crazy-coverage.parser.lcov"),
  llvm_json = require("crazy-coverage.parser.llvm_json"),
  cobertura = require("crazy-coverage.parser.cobertura"),
  gcov = require("crazy-coverage.converter.gcov"),
  llvm_profdata = require("crazy-coverage.converter.llvm_profdata"),
}

function M.parse(file_path)
  local format = utils.detect_format(file_path)
  local parser = M.parsers[format]
  return parser.parse(file_path)
end
```

### Adding a New Parser

1. Create `lua/coverage/parser/myformat.lua`:
   ```lua
   local M = {}
   
   function M.parse(file_path)
     -- Read and parse file
     local coverage_data = { files = {} }
     -- ... parsing logic
     return coverage_data
   end
   
   return M
   ```

2. Register in `lua/coverage/parser/init.lua`:
   ```lua
   M.parsers.myformat = require("crazy-coverage.parser.myformat")
   ```

3. Update format detection in `lua/coverage/utils.lua`:
   ```lua
   if ext == "myext" then
     return "myformat"
   end
   ```

## Converter Layer

### Converter Interface

Converters wrap external tools to transform binary formats:

```lua
function M.parse(file_path)
  -- 1. Convert binary to text format
  local temp_file = convert_to_text(file_path)
  
  -- 2. Parse using existing parser
  local parser = require("crazy-coverage.parser.lcov")
  return parser.parse(temp_file)
end
```

### GCOV Converter

Wraps `lcov` tool:

```lua
-- lua/coverage/converter/gcov.lua
function M.convert_gcov_to_lcov(work_dir)
  local cmd = "lcov --directory " .. work_dir .. 
              " --capture --output-file coverage_gcov.lcov"
  vim.fn.system(cmd)
  return "coverage_gcov.lcov"
end
```

### Adding a New Converter

1. Create `lua/coverage/converter/myformat.lua`:
   ```lua
   local M = {}
   
   function M.parse(file_path)
     -- Convert to intermediate format
     local json_file = convert_to_json(file_path)
     
     -- Use existing JSON parser
     local json_parser = require("crazy-coverage.parser.llvm_json")
     return json_parser.parse(json_file)
   end
   
   return M
   ```

2. Register as a parser format

## Renderer Layer

### Rendering Pipeline

```lua
-- 1. Clear existing marks
renderer.clear_all()

-- 2. For each file in coverage data
for _, file_entry in ipairs(coverage_data.files) do
  local buf = utils.get_buffer_by_path(file_entry.path)
  
  -- 3. Render lines
  for _, line_info in ipairs(file_entry.lines) do
    local hl = line_info.covered and "CoverageCovered" or "CoverageUncovered"
    local virt_text = { {" " .. line_info.hit_count, hl} }
    
    -- 4. Place extmark
    vim.api.nvim_buf_set_extmark(buf, namespace, line_info.line_num - 1, 0, {
      virt_text = virt_text,
      virt_text_pos = config.virt_text_pos
    })
  end
end
```

### Extmark Management

- Uses a dedicated namespace: `vim.api.nvim_create_namespace("coverage")`
- Extmarks are buffer-local and cleared when buffers unload
- Virtual text position is configurable

## Extending for Other Languages

### 1. Add Language Patterns

Edit `lua/coverage/config.lua`:

```lua
coverage_patterns = {
  c = { "*.lcov", "coverage.json" },
  cpp = { "*.lcov", "coverage.json" },
  python = { ".coverage", "coverage.xml" },  -- New!
  rust = { "cobertura.xml" },                -- New!
  go = { "coverage.out" },                   -- New!
}
```

### 2. Add Language-Specific Parser

For Python's `.coverage` SQLite format:

```lua
-- lua/coverage/parser/python_coverage.lua
local M = {}

function M.parse(file_path)
  -- Use Python to export .coverage to JSON
  local json_file = "/tmp/coverage.json"
  vim.fn.system("coverage json -o " .. json_file)
  
  -- Parse JSON
  local json_parser = require("crazy-coverage.parser.llvm_json")
  return json_parser.parse(json_file)
end

return M
```

### 3. Register Format

```lua
-- lua/coverage/parser/init.lua
M.parsers.python_coverage = require("crazy-coverage.parser.python_coverage")
```

## Configuration System

### Config Structure

```lua
-- lua/coverage/config.lua
local M = {
  -- Display
  virt_text_pos = "eol",
  show_hit_count = true,
  show_percentage = false,
  show_branch_summary = false,
  
  -- Highlights
  covered_hl = "CoverageCovered",
  uncovered_hl = "CoverageUncovered",
  partial_hl = "CoveragePartial",
  
  -- Auto-loading
  auto_load = true,
  coverage_patterns = { ... },
  project_markers = { ".git", "CMakeLists.txt" }
}
```

### User Customization

Users override via `setup()`:

```lua
require("crazy-coverage").setup({
  show_branch_summary = true,  -- Override default
})
```

## State Management

```lua
-- lua/coverage/init.lua
M.state = {
  current_coverage_data = nil,  -- Parsed CoverageData
  current_coverage_file = nil,  -- File path
  enabled = false                -- Display state
}
```

State is managed through commands:
- `CoverageLoad` - Loads data, sets enabled=true
- `CoverageToggle` - Flips enabled
- `CoverageClear` - Resets state

## Error Handling

Parsers return `nil` on error:

```lua
local coverage_data, err = parser.parse(file_path)
if not coverage_data then
  vim.notify("Coverage Error: " .. err, vim.log.levels.ERROR)
  return
end
```

Converters fail gracefully if tools aren't installed:

```lua
if vim.fn.executable("lcov") == 0 then
  return nil, "lcov tool not found"
end
```
