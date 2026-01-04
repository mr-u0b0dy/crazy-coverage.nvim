# Coverage Examples

This directory contains example projects demonstrating code coverage generation and visualization with crazy-coverage.nvim.

## Structure

```
coverage-examples/
├── c/                    # C examples
│   ├── Makefile          # GCC/LLVM build targets
│   ├── README.md         # C-specific documentation
│   ├── main.c
│   ├── math_utils.c
│   └── math_utils.h
│
└── cpp/                  # C++ examples
    ├── Makefile          # GCC/LLVM build targets
    ├── README.md         # C++-specific documentation
    ├── main.cpp
    ├── math_utils.cpp
    └── math_utils.hpp
```

## Quick Start

### C Examples

```bash
cd c
make help           # Show available targets
make lcov           # Build with GCC and generate LCOV coverage
# Then load in Neovim: :CoverageLoad build/coverage/coverage.lcov
```

### C++ Examples

```bash
cd cpp
make help           # Show available targets
make lcov           # Build with GCC and generate LCOV coverage
# Then load in Neovim: :CoverageLoad build/coverage/coverage.lcov
```

## Available Coverage Tools

### GCC/GCOV (LCOV Format)

Generate coverage with GCC and LCOV:

```bash
cd c                # or cpp
make lcov           # Build, run, and generate LCOV report
```

**Advantages:**
- Works with most C/C++ compilers
- Fast coverage generation
- Industry standard format

### LLVM/Clang (JSON Format)

Generate coverage with LLVM:

```bash
cd c                # or cpp
make llvm-report    # Build, run, and generate JSON report
```

**Advantages:**
- More detailed branch coverage
- JSON format for programmatic access
- Modern tooling

## Supported Coverage Formats

| Format | Location | Tool | Load Command |
|--------|----------|------|--------------|
| LCOV | `build/coverage/coverage.lcov` | GCC/LLVM | `:CoverageLoad build/coverage/coverage.lcov` |
| JSON | `build/coverage/coverage.json` | LLVM | `:CoverageLoad build/coverage/coverage.json` |

## Build Commands Summary

### C Example

```bash
cd c
make gcov           # Build with GCC coverage support
make lcov           # Build + run + generate LCOV report
make llvm           # Build with LLVM coverage support
make llvm-report    # Build + run + generate JSON report
make run            # Run program (generates coverage data)
make clean          # Remove build artifacts
```

### C++ Example

```bash
cd cpp
make gcov           # Build with GCC coverage support
make lcov           # Build + run + generate LCOV report
make llvm           # Build with LLVM coverage support
make llvm-report    # Build + run + generate JSON report
make run            # Run program (generates coverage data)
make clean          # Remove build artifacts
```

## Features

- **Multi-language support**: C and C++ examples
- **Multiple coverage tools**: GCC (LCOV) and LLVM (JSON)
- **Clean build system**: Artifacts in `build/` directory only
- **Intentional gaps**: Some code paths are intentionally untested to demonstrate visualization
- **Documentation**: Each example includes detailed README with instructions

## Requirements

For GCC/LCOV:
```bash
sudo apt-get install gcc g++ lcov  # Ubuntu/Debian
sudo yum install gcc gcc-c++ lcov  # RHEL/CentOS
brew install gcc lcov              # macOS
```

For LLVM:
```bash
sudo apt-get install clang llvm    # Ubuntu/Debian
sudo yum install clang llvm        # RHEL/CentOS
brew install llvm                  # macOS
```

## Notes

- All build artifacts are placed in the `build/` directory
- Coverage reports are in `build/coverage/` subdirectory
- Original source files are never modified
- Multiple coverage formats can coexist
- Use `make clean` to remove all artifacts

## Using with crazy-coverage.nvim

After generating coverage:

```vim
" Load GCC/LCOV coverage
:CoverageLoad build/coverage/coverage.lcov

" Load LLVM JSON coverage
:CoverageLoad build/coverage/coverage.json

" Toggle overlay
:CoverageToggle

" Navigate
}u    " Next uncovered line
{u    " Previous uncovered line
}c    " Next covered line
```

For AstroVim users, see [config examples/astrovim-config.lua](../config%20examples/astrovim-config.lua) for keybinding setup.
