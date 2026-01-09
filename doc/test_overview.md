# Test Overview

This document describes the test structure for crazy-coverage.nvim and guides developers on how to write, run, and maintain tests.

## Overview

The test suite has been simplified and consolidated to eliminate duplication while maintaining comprehensive coverage:

- **836 lines** in `spec/parsers_spec.lua` - comprehensive parser tests
- **40 lines** in `test/helpers.lua` - shared test utilities
- **80 lines** in `test/run_all.lua` - headless test runner
- **Unified structure** - all tests organized in single spec file with logical describe blocks

## Test Organization

### Spec Tests (Primary Test Suite)

Located in `test/spec/`, run with `busted`:

```bash
cd /path/to/crazy-coverage.nvim
busted test/spec/
```

#### Main Test File

1. **parsers_spec.lua** (836 lines)
   - LLVM JSON parser tests
   - Cobertura XML parser tests
   - LCOV parser tests
   - Parser dispatcher tests
   - Edge case tests
   - Path resolution tests
   - Path normalization edge cases
   - Input validation
   - Format detection
   - Parser edge cases (multi-file, empty, malformed)
   - Coverage file caching tests
   - Buffer matching edge cases

### Headless Test Runner

Quick manual testing without full Neovim environment:

```bash
nvim --headless -u NONE -c "lua dofile('test/run_all.lua')" +qa
```

Tests:
- Format detection
- Path normalization
- Parser error handling
- Buffer matching
- Actual file parsing

## Test Helpers

### helpers.lua

Common testing utilities:

```lua
-- Create temporary coverage files
temp_file, temp_dir = helpers.create_temp_coverage_file("lcov", content)
helpers.cleanup_temp_dir(temp_dir)

-- Create mock buffers
mock_buf = helpers.create_mock_buffer(path, content)

-- Sample coverage data
helpers.sample_llvm_coverage()
helpers.sample_cobertura_coverage()
helpers.sample_lcov_coverage()
```

## Running Tests

### Option 1: Full Test Suite with Busted

```bash
# Run all spec tests (single comprehensive file)
busted test/spec/parsers_spec.lua

# Run specific test group
busted test/spec/parsers_spec.lua --filter "LCOV"

# Run with coverage report
busted --coverage test/spec/parsers_spec.lua
```

### Option 2: Quick Headless Test

```bash
# Run quick test suite
nvim --headless -u NONE -c "lua dofile('test/run_all.lua')" +qa

# From project root in Neovim
:!nvim --headless -u NONE -c "lua dofile('test/run_all.lua')" +qa
```

### Option 3: Individual File Tests

```bash
# Test specific fixture file
nvim --headless -u NONE -c "lua require('crazy-coverage.parser').parse('test/fixtures/sample_coverage.lcov')" +qa
```

## Test Structure

### Parser Tests (parsers_spec.lua)

Each parser has:
- Path resolution tests (relative, absolute, multiple segments)
- Format-specific parsing tests (segments, lines, branches)
- Edge case handling

Example structure:
```lua
describe("LLVM JSON Parser", function()
  describe("path resolution", function()
    it("should resolve relative paths", function() ... end)
    it("should preserve absolute paths", function() ... end)
  end)
  
  describe("segments parsing", function()
    it("should extract execution counts", function() ... end)
  end)
end)
```

### Test Organization by Category

- **Parser tests**: Format-specific parsing and path resolution
- **Dispatcher tests**: Format detection, project_root handling, error handling
- **Path resolution tests**: normalize_path() behavior, path matching
- **Input validation tests**: nil/empty handling across utilities
- **Format detection tests**: All supported file extension detection
- **Edge case tests**: Multi-file, empty, malformed coverage data
- **Caching tests**: Coverage file caching structure and normalization

### Fixtures

Located in `test/fixtures/`:

- `sample_coverage.lcov` - Single-file LCOV
- `sample_coverage_multi.lcov` - Multi-file LCOV
- `sample_coverage_empty.lcov` - Empty LCOV
- `sample_coverage.json` - LLVM JSON
- `sample_coverage.xml` - Cobertura XML

## Test Data Generators

Helpers provide inline coverage data for temporary file testing:

```lua
-- In tests
temp_file, temp_dir = helpers.create_temp_coverage_file("lcov", helpers.sample_lcov_coverage())
-- Use temp_file...
helpers.cleanup_temp_dir(temp_dir)
```

## Coverage Goals

Current test coverage:

| Component | Coverage |
|-----------|----------|
| Parsers (LCOV, JSON, XML) | ~95% |
| Path Resolution | ~100% |
| Format Detection | ~100% |
| Error Handling | ~90% |
| Renderer (Buffer Matching) | ~80% |

## Adding New Tests

1. **For parser changes**: Add tests to `spec/parsers_spec.lua`
   ```lua
   describe("New Parser", function()
     it("should parse new format", function() ... end)
   end)
   ```

2. **For quick manual testing**: Update `test/run_all.lua`

## CI/CD Integration

Recommended GitHub Actions workflow:

```yaml
- name: Run tests
  run: busted test/spec/ --coverage

- name: Quick headless test
  run: nvim --headless -u NONE -c "lua dofile('test/run_all.lua')" +qa
```

## Troubleshooting

### Busted not found
```bash
# Install busted
luarocks install busted

# Or use with neovim
nvim -c "luafile test/spec/run_tests.sh"
```

### Test file not found
- Ensure working directory is project root
- Check fixture files exist in `test/fixtures/`
- Verify Lua path includes `lua/?.lua`

### Temporary file permission errors
- Check `/tmp/` is writable
- May need to run with sudo or change temp directory

### Vim API not available in headless mode
- Some tests requiring `vim.*` API will be skipped
- Use full Busted suite for complete coverage
