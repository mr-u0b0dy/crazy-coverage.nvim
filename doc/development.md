# Development

## Running Tests

### Quick Tests (Headless, No Dependencies)

The fastest way to test without installing plenary:

```bash
cd nvim-crazy-coverage
nvim --headless -u NONE +"lua dofile('test/run_tests.lua')" +qa
```

This runs basic assertions for all parsers (LCOV, JSON, XML).

### Plenary/Busted Tests (Organized Suites)

For comprehensive testing with organized test suites:

```bash
# Requires plenary.nvim plugin installed
nvim --headless --noplugin -u NONE \
  -c "set rtp+=$(pwd)" \
  -c "luafile test/spec/run_tests.lua" +qa!
```

Or use the bash wrapper:
```bash
bash test/spec/run_tests.sh
```

### Test Structure

```
test/
├── spec/                      # Plenary/Busted suites
│   ├── lcov_parser_spec.lua   # LCOV parser tests
│   ├── json_parser_spec.lua   # LLVM JSON parser tests
│   ├── cobertura_parser_spec.lua # Cobertura XML parser tests
│   ├── edge_cases_spec.lua    # Multi-file, empty, detection
│   ├── run_tests.lua          # Plenary test runner
│   └── run_tests.sh           # Bash wrapper
├── fixtures/                  # Sample coverage files
├── run_tests.lua              # Legacy headless tests
├── run_parse.lua              # Parser demo
├── run_render_demo.lua        # Renderer demo
└── test_format_detection.lua  # Format detection test
```

### Test Fixtures

```
test/fixtures/
├── sample_coverage.lcov       # Single-file LCOV
├── sample_coverage_multi.lcov # Multi-file LCOV
├── sample_coverage_empty.lcov # Empty LCOV
├── sample_coverage.json       # LLVM JSON
└── sample_coverage.xml        # Cobertura XML
```

## CI/CD

### GitHub Actions

The project includes a basic GitHub Actions workflow:

```yaml
# .github/workflows/test.yml
name: Tests
on: [push, pull_request]
jobs:
  test:
    runs-on: ubuntu-latest
    strategy:
      matrix:
        nvim-version: [stable, nightly]
    steps:
      - uses: actions/checkout@v3
      - name: Install Neovim
        uses: rhysd/action-setup-vim@v1
        with:
          neovim: true
          version: ${{ matrix.nvim-version }}
      - name: Run tests
        run: |
          nvim --headless --noplugin -u NONE \
            +"lua dofile('test/run_tests.lua')" +qa!
```

## Adding New Parser Tests

### 1. Create Test Suite

```lua
-- test/spec/myformat_parser_spec.lua
local assert = require("luassert")
local parser = require("crazy-coverage.parser")

describe("MyFormat Parser", function()
  it("parses sample file", function()
    local data = parser.parse("test/fixtures/sample.myformat")
    assert.is_not_nil(data)
    assert.equal(1, #data.files)
  end)
  
  it("handles line coverage", function()
    local data = parser.parse("test/fixtures/sample.myformat")
    local f = data.files[1]
    assert.is_true(#f.lines > 0)
  end)
end)
```

### 2. Add Fixture

Create `test/fixtures/sample.myformat` with test data.

### 3. Update Test Runner

Add to `test/spec/run_tests.lua`:
```lua
require("test.spec.myformat_parser_spec")
```

## Manual Testing

### Interactive Testing

```bash
# Start Neovim with plugin on your runtimepath
nvim -u NONE -c "set rtp+=$(pwd)" -c "lua require('crazy-coverage').setup({ auto_load = false })"

# In Neovim
:CoverageLoad test/fixtures/sample_coverage.lcov
:edit src/math.c  # Matches the fixture path
```

### Debug Mode

Add debug prints in parsers:

```lua
-- lua/coverage/parser/lcov.lua
function M.parse(file_path)
  print("Parsing:", file_path)  -- Debug
  -- ... parser logic
  print("Found files:", #coverage_data.files)  -- Debug
  return coverage_data
end
```

Run with visible output:
```bash
nvim src/math.c
:CoverageLoad test/fixtures/sample_coverage.lcov
```

## Code Style

### Lua Style Guide

- Use 2 spaces for indentation
- Document functions with LuaLS annotations:
  ```lua
  ---@param file_path string
  ---@return table|nil -- CoverageData or nil
  function M.parse(file_path)
  ```
- Keep lines under 100 characters when practical

### Naming Conventions

- **Modules**: lowercase with underscores (`lcov.lua`, `llvm_json.lua`)
- **Functions**: lowercase with underscores (`parse_line`, `extract_xml_nodes`)
- **Constants**: UPPERCASE (`M.COVERAGE_PATTERNS`)
- **Private functions**: `local` and prefixed with underscore (`local function _helper()`)

## Contributing Guidelines

### Before Submitting PR

1. **Run tests**: Ensure all tests pass
   ```bash
  bash test/spec/run_tests.sh
   ```

2. **Test manually**: Load sample coverage and verify display
   ```bash
  nvim -u NONE -c "set rtp+=$(pwd)" -c "lua require('crazy-coverage').setup({ auto_load = false })"
  :CoverageLoad test/fixtures/sample_coverage.lcov
   ```

3. **Check format detection**: New formats should auto-detect
   ```bash
  nvim --headless -u NONE +"lua dofile('test/test_format_detection.lua')" +qa
   ```

4. **Update docs**: Add format to `doc/formats.md` if applicable

### PR Checklist

- [ ] Tests pass
- [ ] New parser/format includes test suite
- [ ] New fixtures added to `test/fixtures/`
- [ ] Documentation updated
- [ ] Format detection works
- [ ] No breaking changes (or clearly documented)

### Areas for Contribution

#### High Priority
- [ ] Native GCOV binary parsing (remove lcov dependency)
- [ ] Native LLVM Profdata parsing (remove llvm-cov dependency)
- [ ] File watcher for auto-reload on coverage changes
- [ ] Coverage summary command (total %, files covered)
- [ ] Jump to next/previous uncovered line command

#### Medium Priority
- [ ] Python coverage support (`.coverage` SQLite)
- [ ] Go coverage support (`coverage.out`)
- [ ] Rust coverage support (`llvm-cov` for Rust)
- [ ] JavaScript coverage support (Istanbul/NYC JSON)
- [ ] Region highlighting (not just virtual text)
- [ ] Gutter signs for covered/uncovered lines

#### Low Priority
- [ ] Coverage diff (compare two coverage runs)
- [ ] Telescope integration (search uncovered functions)
- [ ] Status line integration (show % for current file)
- [ ] Coverage heat map (gradient colors by hit count)

## Project Structure

```
nvim-coverage/
├── .github/
│   └── workflows/
│       └── test.yml              # CI configuration
├── doc/
│   ├── usage.md                  # User guide
│   ├── formats.md                # Format documentation
│   ├── architecture.md           # Design documentation
│   └── development.md            # This file
├── lua/coverage/
│   ├── init.lua                  # Main module
│   ├── config.lua                # Configuration
│   ├── renderer.lua              # Rendering engine
│   ├── utils.lua                 # Utilities
│   ├── parser/
│   │   ├── init.lua              # Dispatcher
│   │   ├── lcov.lua              # LCOV parser
│   │   ├── llvm_json.lua         # JSON parser
│   │   └── cobertura.lua         # XML parser
│   └── converter/
│       ├── gcov.lua              # GCOV converter
│       └── llvm_profdata.lua     # Profdata converter
├── plugin/
│   └── coverage.lua              # Plugin entry point
├── test/
│   ├── spec/                     # Plenary/Busted test suites
│   │   ├── *_spec.lua            # Test suites
│   │   ├── run_tests.lua         # Test runner
│   │   └── run_tests.sh          # Bash wrapper
│   ├── fixtures/                 # Test coverage samples
│   ├── run_tests.lua             # Quick tests
│   ├── run_parse.lua             # Parser demo
│   ├── run_render_demo.lua       # Renderer demo
│   └── test_format_detection.lua # Format detection test
├── LICENSE
└── README.md                     # Main documentation
```

## Release Process

1. Update version in plugin metadata
2. Update CHANGELOG.md
3. Tag release: `git tag v1.0.0`
4. Push tag: `git push origin v1.0.0`
5. GitHub Actions runs tests automatically
6. Create GitHub release with notes

## Getting Help

- **Issues**: Open an issue on GitHub with:
  - Neovim version (`nvim --version`)
  - Sample coverage file (if applicable)
  - Error messages
  - Steps to reproduce

- **Discussions**: Use GitHub Discussions for:
  - Feature requests
  - Usage questions
  - Design discussions
