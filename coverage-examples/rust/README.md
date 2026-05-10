# Rust Coverage Examples

Example Rust code demonstrating coverage generation with cargo-tarpaulin for use with crazy-coverage.nvim.

## Quick Start

### 1. Run tests

```bash
cd coverage-examples/rust
make test
```

### 2. Generate LCOV report

```bash
make lcov
```

Load in crazy-coverage.nvim:

```vim
:CoverageLoad build/coverage/coverage.lcov
```

## Available Make Targets

| Command | Description |
|---------|-------------|
| `make help` | Show help message |
| `make test` | Run Rust tests |
| `make lcov` | Generate LCOV report via cargo-tarpaulin |
| `make clean` | Remove build artifacts |

## Directory Structure

```text
rust/
├── Makefile             # Coverage workflow
├── README.md            # This file
├── Cargo.toml           # Rust package manifest
├── src/
│   ├── main.rs          # Example main entrypoint
│   ├── lib.rs           # Library module exports
│   └── math_utils.rs    # Functions under test
├── tests/
│   └── math_tests.rs    # Test cases (intentional coverage gaps)
└── build/               # Build output (created by make)
    └── coverage/
        └── coverage.lcov # LCOV report
```

## Requirements

Install Rust and cargo-tarpaulin:

```bash
rustup toolchain install stable
cargo install cargo-tarpaulin
```

## Notes

- This example uses LCOV output because it integrates directly with crazy-coverage.nvim.
- Some branches and code paths are intentionally untested to visualize uncovered lines.
