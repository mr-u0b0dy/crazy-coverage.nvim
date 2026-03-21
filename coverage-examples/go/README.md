# Go Coverage Examples

Example Go code demonstrating coverage generation with native coverprofile and converted reports for use with crazy-coverage.nvim.

## Quick Start

### 1. Generate native Go coverprofile

```bash
cd coverage-examples/go
make cover
```

Load in crazy-coverage.nvim:

```vim
:CoverageLoad build/coverage.out
```

### 2. Convert to LCOV report

```bash
make lcov
```

Load in crazy-coverage.nvim:

```vim
:CoverageLoad build/coverage/coverage.lcov
```

### 3. Convert to Cobertura XML report

```bash
make cobertura
```

Load in crazy-coverage.nvim:

```vim
:CoverageLoad build/coverage/coverage.xml
```

## Available Make Targets

| Command | Description |
|---------|-------------|
| `make help` | Show help message |
| `make test` | Run Go tests |
| `make cover` | Generate native Go coverprofile |
| `make lcov` | Convert coverprofile to LCOV |
| `make cobertura` | Convert coverprofile to Cobertura XML |
| `make html` | Generate HTML coverage report |
| `make clean` | Remove build artifacts |

## Directory Structure

```
go/
├── Makefile              # Coverage workflow
├── README.md             # This file
├── go.mod                # Go module definition
├── main.go               # Example main entrypoint
├── math_utils.go         # Functions under test
├── math_utils_test.go    # Test cases (intentional coverage gaps)
└── build/                # Build output (created by make)
    ├── coverage.out      # Native Go coverprofile
    └── coverage/
        ├── coverage.lcov # LCOV converted from coverprofile
        ├── coverage.xml  # Cobertura converted from coverprofile
        └── coverage.html # HTML report from go tool cover
```

## Notes

- Native Go support uses the `coverage.out` format directly.
- LCOV conversion is provided for interoperability with tools that consume LCOV.
- Cobertura conversion requires `gocover-cobertura`:

```bash
go install github.com/boumenot/gocover-cobertura@latest
```

- Some branches and code paths are intentionally untested to visualize uncovered lines.
