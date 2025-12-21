-- Parser dispatcher - detects format and routes to appropriate parser
local M = {}
local utils = require("crazy-coverage.utils")

--- Load and cache parser modules
M.parsers = {
  lcov = require("crazy-coverage.parser.lcov"),
  llvm_json = require("crazy-coverage.parser.llvm_json"),
  cobertura = require("crazy-coverage.parser.cobertura"),
  gcov = require("crazy-coverage.converter.gcov"),
  llvm_profdata = require("crazy-coverage.converter.llvm_profdata"),
}

--- Parse coverage file - auto-detect format
---@param file_path string
---@return table|nil, string|nil -- CoverageData or nil, error message
function M.parse(file_path)
  if not file_path or file_path == "" then
    return nil, "File path is required"
  end
  
  if not utils.file_exists(file_path) then
    return nil, "File does not exist: " .. file_path
  end

  local format = utils.detect_format(file_path)

  if not format then
    return nil, "Unknown coverage format for file: " .. file_path
  end

  local parser = M.parsers[format]
  if not parser then
    return nil, "Parser not implemented for format: " .. format
  end
  
  if not parser.parse or type(parser.parse) ~= "function" then
    return nil, "Invalid parser for format: " .. format
  end

  local ok, result = pcall(parser.parse, file_path)
  if not ok then
    return nil, "Failed to parse coverage file: " .. tostring(result)
  end

  if not result then
    return nil, "Parser returned nil for file: " .. file_path
  end
  
  -- Validate result structure
  if type(result) ~= "table" or not result.files then
    return nil, "Parser returned invalid data structure"
  end

  return result, nil
end

--- Register custom parser for a format
---@param format string
---@param parser_module table
function M.register_parser(format, parser_module)
  if not format or format == "" then
    error("Format name is required")
  end
  
  if not parser_module or type(parser_module) ~= "table" then
    error("Parser module must be a table")
  end
  
  if not parser_module.parse or type(parser_module.parse) ~= "function" then
    error("Parser module must have a 'parse' function")
  end
  
  M.parsers[format] = parser_module
end

return M
