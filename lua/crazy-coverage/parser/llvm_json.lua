-- LLVM JSON format parser
local M = {}
local utils = require("crazy-coverage.utils")

--- Parse LLVM JSON format
---@param file_path string
---@return table|nil -- CoverageData model or nil on error
function M.parse(file_path)
  if not utils.file_exists(file_path) then
    return nil
  end

  local lines = utils.read_file(file_path)
  if not lines then
    return nil
  end

  local json_str = table.concat(lines, "\n")
  local json_data = utils.parse_json(json_str)

  if not json_data or not json_data.data then
    return nil
  end

  local coverage_data = {
    files = {},
  }

  -- LLVM JSON structure: { data: [{ files: [...] }] }
  for _, record in ipairs(json_data.data) do
    if record.files then
      for _, file_data in ipairs(record.files) do
        local file_entry = {
          path = file_data.filename,
          lines = {},
          branches = {},
        }

        -- Parse line coverage
        if file_data.lines then
          for _, line_info in ipairs(file_data.lines) do
            local hit_count = line_info.count or 0
            table.insert(file_entry.lines, {
              line_num = line_info.line_number,
              hit_count = hit_count,
              covered = hit_count > 0,
            })

            -- Parse branch coverage from regions if present
            if line_info.regions then
              for idx, region in ipairs(line_info.regions) do
                table.insert(file_entry.branches, {
                  line = line_info.line_number,
                  id = idx,
                  hit_count = region.count or 0,
                })
              end
            end
          end
        end

        table.insert(coverage_data.files, file_entry)
      end
    end
  end

  return coverage_data
end

return M
