-- LLVM Profdata converter: wraps llvm-profdata and llvm-cov to convert .profdata to JSON
-- Requires: llvm-profdata and llvm-cov commands available on system
local M = {}
local utils = require("crazy-coverage.utils")

--- Convert LLVM profdata to JSON format using llvm-cov
---@param profdata_file string -- Path to .profdata file
---@param binary_file string|nil -- Path to instrumented binary (optional, may be auto-detected)
---@return string|nil -- Path to generated JSON file, or nil on error
function M.convert_profdata_to_json(profdata_file, binary_file)
  if not utils.file_exists(profdata_file) then
    return nil
  end

  local output_file = vim.fn.fnamemodify(profdata_file, ":p:h") .. "/coverage_llvm.json"
  
  -- Build llvm-cov command
  local cmd
  if binary_file and utils.file_exists(binary_file) then
    cmd = string.format(
      "llvm-cov export -instr-profile=%s %s > %s 2>/dev/null",
      vim.fn.shellescape(profdata_file),
      vim.fn.shellescape(binary_file),
      vim.fn.shellescape(output_file)
    )
  else
    -- Try to find binary in common locations
    cmd = string.format(
      "llvm-cov export -instr-profile=%s 2>/dev/null || echo 'no output' > %s",
      vim.fn.shellescape(profdata_file),
      vim.fn.shellescape(output_file)
    )
  end

  local result = vim.fn.system(cmd)
  if utils.file_exists(output_file) then
    local content = table.concat(utils.read_file(output_file), "")
    if content:match("^%s*{") then
      return output_file
    end
  end

  return nil
end

--- Auto-detect and convert LLVM profdata
---@param profdata_file string -- Path to .profdata file
---@return table|nil -- CoverageData model or nil on error
function M.parse(profdata_file)
  local json_path = M.convert_profdata_to_json(profdata_file)
  if not json_path then
    return nil
  end

  -- Parse the generated JSON file
  local json_parser = require("crazy-coverage.parser.llvm_json")
  return json_parser.parse(json_path)
end

return M
