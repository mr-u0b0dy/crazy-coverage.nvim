# Rust Coverage Examples

Example Rust code demonstrating coverage generation with cargo-tarpaulin and cargo-llvm-cov for use with crazy-coverage.nvim.

## Quick Start

### 1. Run tests

```bash
cd coverage-examples/rust
make test
```

### 2. Generate LCOV report

```bash
make llvm-cov-lcov
```

Load in crazy-coverage.nvim:

```vim
:CoverageLoad target/coverage/coverage-llvm-cov.lcov
```

## Available Make Targets

| Command | Description |
| --- | --- |
| `make help` | Show help message |
| `make test` | Run Rust tests |
| `make tarpaulin-lcov` | Generate LCOV report via cargo-tarpaulin |
| `make llvm-cov-lcov` | Generate LCOV report via cargo-llvm-cov |
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
└── target/              # Build output (created by make)
    └── coverage/
        ├── coverage-tarpaulin.lcov # Tarpaulin LCOV report
        └── coverage-llvm-cov.lcov  # llvm-cov LCOV report
```

## Requirements

Install Rust, cargo-tarpaulin, and cargo-llvm-cov:

```bash
rustup toolchain install stable
cargo install cargo-tarpaulin
cargo install cargo-llvm-cov
```

## Notes

- Some branches and code paths are intentionally untested to visualize uncovered lines.
