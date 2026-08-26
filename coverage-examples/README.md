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
├── cpp/                  # C++ examples
│   ├── Makefile          # GCC/LLVM build targets
│   ├── README.md         # C++-specific documentation
│   ├── main.cpp
│   ├── math_utils.cpp
│   └── math_utils.hpp
│
├── go/                   # Go examples
│   ├── Makefile          # Go coverage and conversion targets
│   ├── README.md         # Go-specific documentation
│   ├── main.go
│   ├── math_utils.go
│   └── math_utils_test.go
│
├── python/               # Python examples
│   ├── Makefile          # coverage.py targets
│   ├── README.md         # Python-specific documentation
│   ├── pyproject.toml
│   ├── src/
│   └── tests/
│
└── rust/                 # Rust examples
    ├── Makefile          # Rust coverage targets
    ├── README.md         # Rust-specific documentation
    ├── Cargo.toml
    ├── src/
    └── tests/
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

### Go Examples

```bash
cd go
make cover          # Generate native Go coverprofile
make lcov           # Convert to LCOV report
# Then load in Neovim: :CoverageLoad build/coverage.out
```

### Python Examples

```bash
cd python
make coverage       # Creates build/venv (coverage + pytest) on first run, then generates .coverage
make xml            # Export Cobertura XML
make json           # Export coverage.py JSON
make lcov           # Export LCOV report
make html           # Export browsable HTML report (build/coverage/html/index.html)
# Then load in Neovim:
# :CoverageLoad .coverage
# :CoverageLoad build/coverage/coverage.xml
# :CoverageLoad build/coverage/coverage.json
# :CoverageLoad build/coverage/coverage.lcov
```

### Rust Examples

```bash
cd rust
make test                   # Run Rust tests
# Generate LCOV report using the Makefile targets (outputs to target/coverage/)
make tarpaulin-lcov         # Generate LCOV report with cargo-tarpaulin
# Or, using llvm-cov:
# make llvm-cov-lcov        # Generate LCOV report with cargo-llvm-cov
# Then load in Neovim: :CoverageLoad target/coverage/coverage-tarpaulin.lcov
# For llvm-cov output use: :CoverageLoad target/coverage/coverage-llvm-cov.lcov
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
| Go Coverprofile | `build/coverage.out` | Go test | `:CoverageLoad build/coverage.out` |
| Cobertura XML | `build/coverage/coverage.xml` | Go/C/C++ | `:CoverageLoad build/coverage/coverage.xml` |
| Python coverage.py JSON | `build/coverage/coverage.json` | coverage.py | `:CoverageLoad build/coverage/coverage.json` |
| Python .coverage | `.coverage` | coverage.py | `:CoverageLoad .coverage` |

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

### Go Example

```bash
cd go
make test           # Run Go tests
make cover          # Generate native Go coverage profile
make lcov           # Convert coverprofile to LCOV
make cobertura      # Convert coverprofile to Cobertura XML
make html           # Generate HTML report with go tool cover
make clean          # Remove build artifacts
```

### Rust Example

```bash
cd rust
make test           # Run Rust tests
make llvm-cov-lcov  # Generate LCOV report with cargo-llvm-cov
make clean          # Remove build artifacts
```

## Features

- **Multi-language support**: C, C++, Go, Python, and Rust examples
- **Multiple coverage tools**: GCC (LCOV), LLVM (JSON), and coverage.py
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

For Go tools:

```bash
sudo apt-get install golang-go     # Ubuntu/Debian
sudo yum install golang            # RHEL/CentOS
brew install go                    # macOS

# Optional (for Cobertura conversion in Go example)
go install github.com/boumenot/gocover-cobertura@latest
```

For Python tools:

```bash
python3 -m venv --help  # confirm the standard `venv` module is available
```

`coverage` and `pytest` don't need to be installed manually — `python/Makefile` provisions its own
virtualenv at `python/build/venv` and installs them there automatically. This avoids
"externally managed environment" `pip install` failures on distros like Arch, Debian, or Ubuntu.

For Rust tools:

```bash
rustup toolchain install stable
cargo install cargo-tarpaulin
cargo install cargo-llvm-cov
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
" Single command to toggle coverage on/off
:CoverageToggle              " Auto-loads coverage, watches for changes, enables overlay

" Display toggle
:CoverageToggleHitCount      " Toggle hit count display on/off

" Manual load (optional)
:CoverageLoad build/coverage/coverage.lcov
```

### Smart Toggle Features

When you enable coverage with `:CoverageToggle`:

- ✓ Automatically finds and loads coverage file in project
- ✓ Watches coverage file for changes and auto-reloads
- ✓ Shows notification when coverage file is updated
- ✓ Enables overlay with hit counts (configurable default)

When you disable with `:CoverageToggle`:

- ✓ Clears all coverage overlays
- ✓ Stops file watching
- ✓ Cleans up all resources

### Navigation Keybindings

With the AstroVim configuration (see [configs/astrovim-config.lua](../configs/astrovim-config.lua)):

**Coverage Management** (`<leader>c` prefix):

- `<leader>ct` - Toggle coverage overlay (auto-loads, watches for changes)
- `<leader>ch` - Toggle hit count display

**Navigation** (`[/]` then `c` then `c/p/u`):

- `]cc` / `[cc` - Next/Previous covered line
- `]cp` / `[cp` - Next/Previous partially covered line
- `]cu` / `[cu` - Next/Previous uncovered line

The navigation follows Vim's natural `{` and `}` motion keys for moving between blocks, making it intuitive to jump between coverage regions.

### Configuration Options

```lua
require("crazy-coverage").setup({
  default_show_hit_count = true,  -- Show hit counts by default when overlay is enabled
  enable_line_hl = true,          -- Enable line highlighting
  virt_text_pos = "eol",          -- Position: "eol", "inline", "overlay", "right_align"
})
```
