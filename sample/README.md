# Sample C/C++ Coverage Project

This directory contains sample C code for testing coverage reporting with crazy-coverage.nvim.

## Building and Running

### GCC Coverage (gcov)

```bash
# Build with coverage support
make coverage

# Run the program to generate coverage data
make run

# Generate LCOV report
make lcov-report

# Generate Cobertura XML report
make cobertura-report

# Generate HTML report (optional)
make html-report
```

### LLVM Coverage (llvm-cov)

```bash
# Build with LLVM coverage support
make llvm-coverage

# Run the program with profiling
LLVM_PROFILE_FILE="math_test.profraw" ./math_test

# Process coverage data
make llvm-report
```

## Files Generated

- **coverage.info** - LCOV format coverage data
- **coverage.xml** - Cobertura XML format coverage data
- **coverage.lcov** - LLVM LCOV format coverage data
- **coverage.json** - LLVM JSON format coverage data
- **\*.gcda, \*.gcno** - GCC coverage data files

## Intentionally Uncovered Code

Some code paths are intentionally not tested to demonstrate coverage visualization:
- Division by zero error handling
- Negative input to factorial
- Some edge cases in is_prime

## Using with crazy-coverage.nvim

After generating coverage data, open the source files in Neovim and use the crazy-coverage plugin to visualize the coverage information.
