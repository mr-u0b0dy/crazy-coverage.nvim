-- Shared helpers for JSON-based coverage parsers
local M = {}
local utils = require("crazy-coverage.utils")

--- Read and decode a JSON coverage file.
---@param file_path string
---@return table|nil
function M.read(file_path)
  if not utils.file_exists(file_path) then
    return nil
  end

  local lines = utils.read_file(file_path)
  if not lines then
    return nil
  end

  local json_str = table.concat(lines, "\n")
  return utils.parse_json(json_str)
end

--- Create the standard coverage file entry shape.
---@param source_format string
---@return table
function M.new_file_entry(source_format)
  return {
    lines = {},
    branches = {},
    source_format = source_format,
  }
end

--- Sort line entries by line number for stable output.
---@param file_entry table
function M.sort_lines(file_entry)
  table.sort(file_entry.lines, function(a, b)
    return a.line < b.line
  end)
end

return M

