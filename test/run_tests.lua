-- Headless test runner for coverage parsers
-- Usage: nvim --headless -u NONE +"lua dofile('test/run_tests.lua')" +qa

local cwd = vim.fn.getcwd()
package.path = package.path .. ';' .. cwd .. '/lua/?.lua;' .. cwd .. '/lua/?/init.lua;' .. cwd .. '/lua/?/?.lua'

local parser = require('crazy-coverage.parser')

local function test_suite()
  local passed = 0
  local failed = 0

  -- Test LCOV parsing
  local data = parser.parse(cwd .. '/test/fixtures/sample_coverage.lcov')
  if data and #data.files == 1 then
    passed = passed + 1
    print('✓ LCOV parser')
  else
    failed = failed + 1
    print('✗ LCOV parser')
  end

  -- Test LLVM JSON parsing
  data = parser.parse(cwd .. '/test/fixtures/sample_coverage.json')
  if data and #data.files == 1 then
    passed = passed + 1
    print('✓ LLVM JSON parser')
  else
    failed = failed + 1
    print('✗ LLVM JSON parser')
  end

  -- Test Cobertura parsing
  data = parser.parse(cwd .. '/test/fixtures/sample_coverage.xml')
  if data and #data.files == 1 then
    passed = passed + 1
    print('✓ Cobertura parser')
  else
    failed = failed + 1
    print('✗ Cobertura parser')
  end

  -- Test error handling
  data = parser.parse('/nonexistent/file.lcov')
  if not data then
    passed = passed + 1
    print('✓ Error handling')
  else
    failed = failed + 1
    print('✗ Error handling')
  end

  return { passed = passed, failed = failed }
end

local results = test_suite()
print(string.format('\nResults: %d passed, %d failed', results.passed, results.failed))

if results.failed > 0 then
  vim.cmd('cq')
end
