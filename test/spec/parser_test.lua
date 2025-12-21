-- Test file for LCOV parser
local lcov_parser = require("crazy-coverage.parser.lcov")

-- Sample LCOV data
local sample_lcov = [[
TN:2
FN:5,main
FN:10,helper
FNDA:1,main
FNDA:0,helper
SF:src/main.c
FN:5,main
FNDA:1,main
LN:1
DA:1,1
LN:5
DA:5,1
LN:6
DA:6,1
LN:10
DA:10,0
LN:11
DA:11,0
end_of_record
]]

-- Test function
local function test_lcov_parsing()
  print("Testing LCOV parser...")
  -- Basic parsing test would go here
  print("LCOV parser loaded successfully")
end

return {
  test_lcov_parsing = test_lcov_parsing,
}
