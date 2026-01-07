# Coverage File Discovery

This document explains how the crazy-coverage.nvim plugin intelligently discovers coverage files.

## Overview

The plugin uses a multi-level approach to automatically find your coverage file:

1. **Smart Directory Search** - Searches standard coverage directories in order
2. **Content Inspection** - Verifies files are actually coverage files by reading content
3. **Format Detection** - Automatically detects LCOV, JSON, XML, GCOV, LLVM Profdata
4. **Flexible Configuration** - Supports custom search directories

## How It Works

### Step 1: Find Project Root

The plugin searches upward from the current file location for project markers:
- `.git` - Git repository
- `CMakeLists.txt` - CMake project
- `Makefile` - Make project
- `compile_commands.json` - Compilation database
- Custom markers can be configured

### Step 2: Search Coverage Directories

Default search order (relative to project root):
1. `build/coverage/` - CMake standard build directory
2. `coverage/` - Standard coverage directory
3. `build/` - Build directory root
4. `.` - Project root

### Step 3: Verify File is Coverage Format

For each file found, the plugin checks if it's actually a coverage file by:

**Reading first 10 lines and detecting format:**

- **LCOV**: Lines contain `TN:`, `FN:`, `DA:`, or `end_of_record`
- **LLVM JSON**: Contains `"version"` and `"data"` fields
- **Cobertura XML**: Contains `<coverage>`, `<package>`, `<class>`, or `<line>` tags
- **File Extension Fallback**: `.lcov`, `.info`, `.json`, `.xml`, `.profdata`, `.gcda`, `.gcno`

### Step 4: Return First Valid File

Returns the first file that passes verification, or `nil` if none found.

## Configuration

### Custom Search Directories

```lua
require("crazy-coverage").setup({
  coverage_dirs = {
    "build/coverage",
    ".coverage",           -- Python coverage
    "build/reports",       -- Custom build reports
    "htmlcov",             -- Coverage HTML export
    "coverage",
    ".",
  }
})
```

### Custom Project Markers

```lua
require("crazy-coverage").setup({
  project_markers = {
    ".git",
    "CMakeLists.txt",
    "Makefile",
    "compile_commands.json",
    "package.json",        -- JavaScript projects
    "Cargo.toml",          -- Rust projects
    "pom.xml",             -- Java/Maven projects
    "build.gradle",        -- Gradle projects
  }
})
```

## Supported Formats

All formats are auto-detected by content:

| Format | File Names | Detection |
|--------|-----------|-----------|
| LCOV | `*.lcov`, `*.info` | `TN:`, `FN:`, `DA:`, `end_of_record` |
| LLVM JSON | `*.json` | `"version"`, `"data"` |
| Cobertura XML | `*.xml` | `<coverage>`, `<package>`, `<class>` |
| GCOV | `*.gcda`, `*.gcno` | File extension (binary) |
| LLVM Profdata | `*.profdata` | File extension (binary) |

## Examples

### Example 1: CMake Project

```
project/
├── CMakeLists.txt          ← Project marker
├── src/
│   └── main.cpp
├── build/
│   └── coverage/
│       └── coverage.lcov   ← Auto-detected!
└── coverage_example.json   ← Also auto-detected!
```

The plugin finds either file automatically - no configuration needed!

### Example 2: Custom Coverage Location

```
project/
├── Makefile                ← Project marker
├── src/
├── .coverage_reports/
│   └── my_data.json        ← Custom location, custom name!
└── build/
```

```lua
require("crazy-coverage").setup({
  coverage_dirs = {
    ".coverage_reports",
    "build",
    ".",
  }
})
```

### Example 3: Multiple Projects

```
workspace/
├── project-a/
│   ├── .git                ← Marker
│   └── build/
│       └── cov             ← Any filename works!
│
├── project-b/
│   ├── CMakeLists.txt      ← Marker
│   └── coverage/
│       └── data.xml        ← Auto-detected!
│
└── project-c/
    ├── Makefile            ← Marker
    └── htmlcov/
        └── coverage_2025.json ← Any name, auto-detected!
```

Each project is handled independently based on its project root marker.

## Filename Doesn't Matter

The plugin doesn't care about filenames or extensions:

```
✓ coverage                    (no extension)
✓ coverage_report             (no extension)
✓ cov_data                    (no extension)
✓ coverage_2025_01_09.json    (custom name)
✓ results.xml                 (non-standard name)
✓ my_coverage_report.data     (any extension)
```

All are detected as long as they contain valid coverage data!

## Performance

- **First 10 lines**: Only reads first 10 lines for format detection (fast)
- **Binary files**: Detects GCOV/LLVM Profdata by extension (instant)
- **Caching**: Coverage data is cached after parsing (fast reload)

## Troubleshooting

### Coverage File Not Found

1. Check project marker exists (`.git`, `CMakeLists.txt`, `Makefile`, etc.)
2. Coverage file is in one of the search directories
3. Try manual load: `:CoverageLoad /path/to/coverage/file`

### Wrong File Being Loaded

1. Check file order in `coverage_dirs` (first match is used)
2. Verify file content matches coverage format
3. Manually specify file: `:CoverageLoad /path/to/correct/file`

### Custom Directory Not Searched

1. Verify directory is relative to project root (not absolute path)
2. Check directory exists and contains coverage file
3. Add to `coverage_dirs` config and restart Neovim
