#!/usr/bin/env lua

-- Test script to verify parsers work correctly
package.path = package.path .. ";./lua/?.lua;./lua/?/init.lua"

-- Test LLVM JSON parser
print("=== Testing LLVM JSON Parser ===")
local llvm_parser = require("crazy-coverage.parser.llvm_json")
local llvm_result = llvm_parser.parse("coverage-examples/c/build/coverage.json")

if llvm_result then
  print("✓ LLVM Parser returned data")
  print("  Files: " .. #llvm_result.files)
  for i, file in ipairs(llvm_result.files) do
    print(string.format("  [%d] %s - %d lines", i, file.path, #file.lines))
    if #file.lines > 0 then
      print(string.format("      First line: %d (hits: %d)", file.lines[1].line_num, file.lines[1].hit_count))
    end
  end
else
  print("✗ LLVM Parser failed")
end

print("\n=== Testing Cobertura Parser ===")
-- Generate Cobertura first
os.execute("cd coverage-examples/c && make cobertura > /dev/null 2>&1")

local cobertura_parser = require("crazy-coverage.parser.cobertura")
local cobertura_result = cobertura_parser.parse("coverage-examples/c/build/coverage.xml")

if cobertura_result then
  print("✓ Cobertura Parser returned data")
  print("  Files: " .. #cobertura_result.files)
  for i, file in ipairs(cobertura_result.files) do
    print(string.format("  [%d] %s - %d lines", i, file.path, #file.lines))
    if #file.lines > 0 then
      print(string.format("      First line: %d (hits: %d)", file.lines[1].line_num, file.lines[1].hit_count))
    end
  end
else
  print("✗ Cobertura Parser failed")
end
