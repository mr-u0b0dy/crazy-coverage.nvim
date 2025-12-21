-- GCOV converter: wraps lcov to convert .gcda/.gcno to LCOV format
-- Requires: lcov command available on system
local M = {}
local utils = require("crazy-coverage.utils")

--- Convert GCOV data to LCOV format using lcov tool
---@param work_dir string -- Directory containing .gcda/.gcno files
---@return string|nil -- Path to generated coverage.lcov, or nil on error
function M.convert_gcov_to_lcov(work_dir)
  if not utils.file_exists(work_dir) then
    return nil
  end

  local output_file = work_dir .. "/coverage_gcov.lcov"
  local cmd = string.format(
    "lcov --directory %s --capture --output-file %s 2>/dev/null",
    vim.fn.shellescape(work_dir),
    vim.fn.shellescape(output_file)
  )

  local result = vim.fn.system(cmd)
  if vim.v.shell_error == 0 and utils.file_exists(output_file) then
    return output_file
  end

  return nil
end

--- Auto-detect GCOV directory and convert
---@param gcda_or_dir string -- Path to .gcda file or directory containing GCOV data
---@return string|nil -- Path to generated LCOV file, or nil on error
function M.parse(gcda_or_dir)
  local work_dir = gcda_or_dir
  
  -- If file, use its directory
  if utils.file_exists(gcda_or_dir) and not vim.fn.isdirectory(gcda_or_dir) then
    work_dir = vim.fn.fnamemodify(gcda_or_dir, ":p:h")
  end

  local lcov_path = M.convert_gcov_to_lcov(work_dir)
  if not lcov_path then
    return nil
  end

  -- Parse the generated LCOV file
  local lcov_parser = require("crazy-coverage.parser.lcov")
  return lcov_parser.parse(lcov_path)
end

return M
