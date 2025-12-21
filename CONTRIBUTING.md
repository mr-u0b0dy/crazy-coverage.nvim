# Contributing to crazy-coverage.nvim

We welcome contributions! Here's how you can help:

## Getting Started

1. Fork the repository
2. Clone your fork: `git clone https://github.com/yourusername/crazy-coverage.nvim.git`
3. Create a feature branch: `git checkout -b feature/my-feature`
4. Make your changes
5. Test thoroughly
6. Commit with clear messages: `git commit -m "Add: new feature"`
7. Push to your fork: `git push origin feature/my-feature`
8. Open a Pull Request

## Development Setup

### Prerequisites
- Neovim 0.7+
- Lua 5.1+

### Running Tests
```bash
# Tests coming soon - currently manual testing
# Test with your local Neovim installation:
# nvim --cmd "set rtp+=/path/to/crazy-coverage.nvim"
```

## Areas for Contribution

### Parser Implementations
- [ ] Improve LCOV parser (handle all edge cases)
- [ ] Improve LLVM JSON parser (handle all versions)
- [ ] Improve Cobertura parser (better XML handling)
- [ ] Add GCOV binary format parser
- [ ] Add LLVM Profdata binary format parser
- [ ] Add Python coverage (.coverage) parser
- [ ] Add Rust tarpaulin parser
- [ ] Add Go coverage parser

### Language Support
- [ ] Python language hooks
- [ ] Rust language hooks
- [ ] Go language hooks
- [ ] JavaScript/TypeScript language hooks

### Renderer Improvements
- [ ] Branch coverage visualization
- [ ] Region highlighting (LLVM)
- [ ] Jump to uncovered lines
- [ ] Coverage summary command
- [ ] Line-by-line hit count details

### Performance
- [ ] Lazy parsing (only for open buffers)
- [ ] Result caching
- [ ] Parallel parser execution
- [ ] Memory optimization for large files

### Features
- [ ] File watcher for auto-reload
- [ ] Integration with build systems
- [ ] Diff coverage mode
- [ ] Coverage trends over time

### Documentation
- [ ] Better API documentation
- [ ] Video tutorial
- [ ] Configuration examples
- [ ] Coverage generation guides

### Testing
- [ ] Unit tests for parsers
- [ ] Integration tests
- [ ] End-to-end tests
- [ ] Test fixtures for all formats

## Code Style

- Use consistent Lua style (2-space indentation)
- Add type hints in comments (LuaCATS format for future LSP support)
- Document public functions with clear comments
- Keep functions focused and small

Example:
```lua
--- Parse LCOV format
---@param file_path string
---@return table|nil -- CoverageData or nil on error
function M.parse(file_path)
  -- Implementation
end
```

## Reporting Issues

When reporting issues, please include:
- Neovim version: `nvim --version`
- Coverage format you're using
- Reproducible steps
- Expected vs actual behavior
- Coverage file sample (if possible)

## Commit Messages

Use clear, descriptive commit messages:
- `Add: new feature description`
- `Fix: bug description`
- `Improve: performance/code improvement`
- `Refactor: code reorganization`
- `Docs: documentation updates`
- `Test: add or improve tests`

## Pull Request Process

1. Ensure tests pass (when implemented)
2. Update README.md if adding features
3. Update doc/coverage.txt if relevant
4. Reference any related issues
5. Keep PRs focused on single feature/fix
6. Provide clear description of changes

## License

By contributing, you agree that your contributions will be licensed under the same MIT license as the project.

## Questions?

Feel free to open a discussion or issue with your questions!
