-- Tarpaulin JSON format parser
-- Handles JSON output from cargo tarpaulin --out Json
local M = {}
local utils = require("crazy-coverage.utils")
local json_utils = require("crazy-coverage.parser.json")

--- Resolve a tarpaulin trace key to a normalized absolute path.
---@param trace_path string
---@param project_root string|nil
---@return string|nil
local function resolve_trace_path(trace_path, project_root)
  if not trace_path or trace_path == "" then
    return nil
  end

  if trace_path:sub(1, 1) == "/" then
    return utils.normalize_path(trace_path)
  end

  if project_root and project_root ~= "" then
    return utils.normalize_path(project_root .. "/" .. trace_path)
  end

  return utils.normalize_path(trace_path)
end

--- Parse Tarpaulin JSON format
---@param file_path string
---@param project_root string|nil
---@return table|nil -- Coverage data keyed by file path, or nil on error
function M.parse(file_path, project_root)
  local json_data = json_utils.read(file_path)

  if not json_data or not json_data.traces or type(json_data.traces) ~= "table" then
    return nil
  end

  local coverage_data = {}

  -- Process each file's traces
  for trace_path, traces in pairs(json_data.traces) do
    if type(traces) == "table" then
      local normalized_path = resolve_trace_path(trace_path, project_root)

      if normalized_path then
        local file_entry = json_utils.new_file_entry("tarpaulin")

        -- Group traces by line number (tarpaulin can have multiple traces per line)
        local line_hits = {}
        for _, trace in ipairs(traces) do
          if trace.line and trace.stats and trace.stats.Line ~= nil then
            local line_num = trace.line
            local hit_count = trace.stats.Line

            -- Keep the maximum hit count if multiple traces on same line
            if not line_hits[line_num] or line_hits[line_num] < hit_count then
              line_hits[line_num] = hit_count
            end
          end
        end

        -- Convert to lines array format
        for line_num, hit_count in pairs(line_hits) do
          table.insert(file_entry.lines, {
            line = line_num,
            hits = hit_count,
          })
        end

        -- Sort by line number for consistency
        json_utils.sort_lines(file_entry)

        if #file_entry.lines > 0 then
          coverage_data[normalized_path] = file_entry
        end
      end
    end
  end

  return coverage_data
end

return M
