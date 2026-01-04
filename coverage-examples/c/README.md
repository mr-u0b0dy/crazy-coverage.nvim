# C Coverage Examples

Example C code demonstrating coverage generation with different tools for use with crazy-coverage.nvim.

## Quick Start

### 1. Build with GCC/gcov

```bash
cd coverage-examples/c
make gcov    # Build with GCC coverage
make run     # Run and generate coverage data
```

Coverage data will be in `build/` directory.

### 2. Generate LCOV Report

```bash
make lcov    # Builds, runs, and generates LCOV report
```

Load in crazy-coverage.nvim:
```vim
:CoverageLoad build/coverage/coverage.lcov
```

### 3. Build with LLVM/clang

```bash
make llvm    # Build with LLVM coverage
```

Then run with profiling:
```bash
cd build
LLVM_PROFILE_FILE="math_test.profraw" ./math_test
```

### 4. Generate LLVM JSON Report

```bash
make llvm-report  # Build, run, and generate JSON report
```

Load in crazy-coverage.nvim:
```vim
:CoverageLoad build/coverage/coverage.json
```

## Available Make Targets

| Command | Description |
|---------|-------------|
| `make help` | Show help message |
| `make gcov` | Build with GCC coverage (gcov) |
| `make lcov` | Build with GCC and generate LCOV report |
| `make llvm` | Build with LLVM/clang coverage |
| `make llvm-report` | Build with LLVM and generate JSON report |
| `make run` | Run the test program |
| `make clean` | Remove build artifacts |

## Directory Structure

```
c/
├── Makefile           # Build configuration
├── README.md          # This file
├── main.c             # Main program
├── math_utils.c       # Math utility implementation
├── math_utils.h       # Math utility header
└── build/             # Build output (created by make)
    ├── math_test      # Compiled executable
    ├── *.o            # Object files
    ├── *.gcda         # GCC coverage data
    └── coverage/      # Generated coverage reports
        ├── coverage.lcov   # LCOV format
        └── coverage.json   # LLVM JSON format
```

## Coverage Tools

### GCC Coverage (gcov/lcov)
- **Compiler**: gcc
- **Format**: LCOV (`.lcov`)
- **Tools**: lcov, genhtml
- **Installation**: `apt-get install lcov` (Ubuntu/Debian)

### LLVM Coverage
- **Compiler**: clang
- **Format**: LLVM JSON, LCOV
- **Tools**: llvm-profdata, llvm-cov
- **Installation**: `apt-get install llvm` (Ubuntu/Debian)

## Examples

### Generate GCC coverage and load in Neovim

```bash
cd c
make lcov
# Then in Neovim:
# :CoverageLoad build/coverage/coverage.lcov
```

### Generate LLVM coverage and load in Neovim

```bash
cd c
make llvm-report
# Then in Neovim:
# :CoverageLoad build/coverage/coverage.json
```

### Clean up

```bash
make clean  # Remove all build artifacts
```

## Notes

- Coverage data is generated in the `build/coverage/` directory
- Original source files are not modified
- All intermediate files are contained in the `build/` directory
- Multiple coverage reports can be generated simultaneously
- Negative input to factorial
- Some edge cases in is_prime

## Using with crazy-coverage.nvim

After generating coverage data, open the source files in Neovim and use the crazy-coverage plugin to visualize the coverage information.
