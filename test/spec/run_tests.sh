#!/bin/bash
# Simple test runner script for CI/local use
# Run tests with: bash test/spec/run_tests.sh

set -e

NVIM="${NVIM:-nvim}"

echo "Running crazy-coverage.nvim tests with plenary/busted..."

$NVIM --headless --noplugin -u NONE \
  -c "set rtp+=$(pwd)" \
  -c "lua require('test.spec.lcov_parser_spec')" \
  -c "lua require('test.spec.json_parser_spec')" \
  -c "lua require('test.spec.cobertura_parser_spec')" \
  -c "lua require('test.spec.edge_cases_spec')" \
  -c "luafile test/spec/run_tests.lua" \
  +qa!

echo "All tests passed!"
