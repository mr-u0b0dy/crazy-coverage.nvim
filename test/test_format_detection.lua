-- Test format auto-detection
local cwd = vim.fn.getcwd()
package.path = package.path .. ';' .. cwd .. '/lua/?.lua;' .. cwd .. '/lua/?/init.lua;' .. cwd .. '/lua/?/?.lua'

local utils = require('crazy-coverage.utils')

local tests = {
  { 'sample_coverage.lcov', 'lcov' },
  { 'sample_coverage.json', 'llvm_json' },
  { 'sample_coverage.xml', 'cobertura' },
  { 'file.gcda', 'gcov' },
  { 'coverage.profdata', 'llvm_profdata' },
  { 'coverage.info', 'lcov' },
}

print('Format Detection Tests')
print('=' .. string.rep('=', 40))

local passed = 0
for _, test in ipairs(tests) do
  local path, expected = test[1], test[2]
  local detected = utils.detect_format(path)
  if detected == expected then
    passed = passed + 1
    print(string.format('✓ %s -> %s', path, detected))
  else
    print(string.format('✗ %s -> %s (expected %s)', path, detected or 'nil', expected))
  end
end

print('=' .. string.rep('=', 40))
print(string.format('Result: %d/%d passed', passed, #tests))
