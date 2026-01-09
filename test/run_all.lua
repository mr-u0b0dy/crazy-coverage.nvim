-- Headless test runner for quick manual testing
-- Run with: nvim --headless -u NONE -c "lua dofile('test/run_all.lua')" +qa

local cwd = vim.fn.getcwd()
package.path = package.path .. ';' .. cwd .. '/lua/?.lua;' .. cwd .. '/lua/?/init.lua;' .. cwd .. '/lua/?/?.lua'

local parser = require('crazy-coverage.parser')
local utils = require('crazy-coverage.utils')

print("=" .. string.rep("=", 58))
print("crazy-coverage.nvim - Quick Test Suite")
print("=" .. string.rep("=", 58))

-- Test counters
local passed, failed = 0, 0

local function test(name, fn)
  if pcall(fn) then
    passed = passed + 1
    print("✓ " .. name)
  else
    failed = failed + 1
    print("✗ " .. name)
  end
end

-- 1. Format Detection
print("\n[Format Detection]")
test("Detect LCOV", function()
  assert(utils.detect_format("coverage.lcov") == "lcov")
end)
test("Detect LLVM JSON", function()
  assert(utils.detect_format("coverage.json") == "llvm_json")
end)
test("Detect Cobertura", function()
  assert(utils.detect_format("coverage.xml") == "cobertura")
end)
test("Detect GCOV", function()
  assert(utils.detect_format("file.gcda") == "gcov")
end)

-- 2. Path Normalization
print("\n[Path Normalization]")
test("Normalize absolute path", function()
  local result = utils.normalize_path("/home/user/project/main.c")
  assert(result and result:match("^/") and result:match("main%.c$"))
end)
test("Resolve .. segments", function()
  local result = utils.normalize_path("/home/user/project/build/../main.c")
  assert(result == "/home/user/project/main.c")
end)
test("Handle empty path", function()
  assert(utils.normalize_path("") == nil)
end)
test("Handle nil path", function()
  assert(utils.normalize_path(nil) == nil)
end)

-- 3. Parser Error Handling
print("\n[Parser Error Handling]")
test("Reject nil file path", function()
  local data, err = parser.parse(nil)
  assert(data == nil and err ~= nil)
end)
test("Reject empty file path", function()
  local data, err = parser.parse("")
  assert(data == nil and err ~= nil)
end)
test("Handle non-existent file", function()
  local data = parser.parse("/nonexistent/file.lcov")
  assert(data == nil or (data and next(data) == nil))
end)

-- 4. Buffer Matching
print("\n[Buffer Matching]")
test("Handle nil buffer path", function()
  local result = utils.get_buffer_by_path(nil)
  assert(result == nil)
end)
test("Handle empty buffer path", function()
  local result = utils.get_buffer_by_path("")
  assert(result == nil)
end)

-- 5. Actual File Parsing (if fixtures exist)
print("\n[File Parsing]")
test("Parse LCOV fixture", function()
  local data = parser.parse(cwd .. "/test/fixtures/sample_coverage.lcov")
  assert(data ~= nil and data.files ~= nil)
end)
test("Parse JSON fixture", function()
  local data = parser.parse(cwd .. "/test/fixtures/sample_coverage.json")
  assert(data ~= nil and data.files ~= nil)
end)
test("Parse XML fixture", function()
  local data = parser.parse(cwd .. "/test/fixtures/sample_coverage.xml")
  assert(data ~= nil and data.files ~= nil)
end)

-- Summary
print("\n" .. "=" .. string.rep("=", 58))
print(string.format("Results: %d passed, %d failed", passed, failed))
print("=" .. string.rep("=", 58))

if failed > 0 then
  vim.fn.exit(1)
end
