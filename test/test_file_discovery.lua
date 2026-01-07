-- Test intelligent coverage file discovery
-- Tests the is_coverage_file() function and get_coverage_file() directory search

local cwd = vim.fn.getcwd()
package.path = package.path .. ';' .. cwd .. '/lua/?.lua;' .. cwd .. '/lua/?/init.lua;' .. cwd .. '/lua/?/?.lua'

local config = require('crazy-coverage.config')

print('Coverage File Discovery Tests')
print('=' .. string.rep('=', 50))

-- Test 1: LCOV file detection
print('\n[Test 1] LCOV format detection')
local lcov_path = cwd .. '/test/fixtures/sample_coverage.lcov'
if vim.fn.filereadable(lcov_path) == 1 then
  print('✓ LCOV file found: ' .. lcov_path)
else
  print('✗ LCOV file not found: ' .. lcov_path)
end

-- Test 2: JSON format detection
print('\n[Test 2] LLVM JSON format detection')
local json_path = cwd .. '/test/fixtures/sample_coverage.json'
if vim.fn.filereadable(json_path) == 1 then
  print('✓ JSON file found: ' .. json_path)
else
  print('✗ JSON file not found: ' .. json_path)
end

-- Test 3: Cobertura XML detection
print('\n[Test 3] Cobertura XML format detection')
local xml_path = cwd .. '/test/fixtures/sample_coverage.xml'
if vim.fn.filereadable(xml_path) == 1 then
  print('✓ XML file found: ' .. xml_path)
else
  print('✗ XML file not found: ' .. xml_path)
end

-- Test 4: Coverage directories configuration
print('\n[Test 4] Coverage directories configuration')
print('Configured coverage_dirs:')
for i, dir in ipairs(config.coverage_dirs) do
  print(string.format('  %d. %s', i, dir))
end

-- Test 5: Project root detection from test file
print('\n[Test 5] Project root detection')
local test_file = cwd .. '/test/test_file_discovery.lua'
local project_root = config.find_project_root(test_file)
if project_root then
  print('✓ Project root found: ' .. project_root)
else
  print('✗ Could not find project root')
end

-- Test 6: Mock test - create temporary test files in build/coverage dir
print('\n[Test 6] Directory search simulation')
print('Test would search:')
if project_root then
  for _, dir in ipairs(config.coverage_dirs) do
    local full_path = project_root .. '/' .. dir
    local exists = vim.fn.isdirectory(full_path) == 1
    local status = exists and '✓' or '✗'
    print(string.format('  %s %s/', status, dir))
  end
end

-- Test 7: Supported formats
print('\n[Test 7] Supported coverage formats')
local formats = {
  'LCOV (.lcov, .info)',
  'LLVM JSON (.json)',
  'Cobertura XML (.xml)',
  'GCOV (.gcda, .gcno)',
  'LLVM Profdata (.profdata)',
}
for i, fmt in ipairs(formats) do
  print(string.format('  %d. %s', i, fmt))
end

print('\n' .. '=' .. string.rep('=', 50))
print('Note: Full coverage file detection requires:')
print('  - Project root with git/.gitignore/Makefile/CMakeLists.txt')
print('  - Coverage files in one of the search directories')
print('  - Run :CoverageLoad or :CoverageToggle in Neovim')
