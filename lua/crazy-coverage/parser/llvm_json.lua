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

  -- Get the directory of the coverage file for resolving relative paths
  local coverage_dir = vim.fn.fnamemodify(file_path, ":p:h")

  local coverage_data = {
    files = {},
  }

  -- LLVM JSON structure: { data: [{ files: [...] }] }
  for _, record in ipairs(json_data.data) do
    if record.files then
      for _, file_data in ipairs(record.files) do
        -- Resolve relative paths to absolute paths
        local file_path = file_data.filename
        if file_path and not vim.startswith(file_path, "/") then
          file_path = vim.fn.simplify(coverage_dir .. "/" .. file_path)
        end
        file_path = vim.fn.fnamemodify(file_path, ":p")
        
        local file_entry = {
          path = file_path,
          lines = {},
          branches = {},
        }

        -- Parse segments to extract line coverage
        -- Segments format: [line, col, count, hasCount, isRegionEntry, isGapRegion]
        if file_data.segments then
          local line_coverage = {}  -- Map line_num -> max hit count
          
          for _, segment in ipairs(file_data.segments) do
            local line_num = segment[1]
            local count = segment[3] or 0
            local has_count = segment[4]
            
            -- Only process segments that have execution counts
            if has_count and line_num then
              if not line_coverage[line_num] or line_coverage[line_num] < count then
                line_coverage[line_num] = count
              end
            end
          end
          
          -- Convert map to sorted array
          for line_num, hit_count in pairs(line_coverage) do
            table.insert(file_entry.lines, {
              line_num = line_num,
              hit_count = hit_count,
              covered = hit_count > 0,
            })
          end
          
          -- Sort by line number
          table.sort(file_entry.lines, function(a, b)
            return a.line_num < b.line_num
          end)
        end

        -- Parse branches
        if file_data.branches then
          for idx, branch in ipairs(file_data.branches) do
            -- Branch format: [line, col, endLine, endCol, folded, count, ...]
            table.insert(file_entry.branches, {
              line = branch[1],
              id = idx,
              hit_count = branch[6] or 0,
            })
          end
        end

        table.insert(coverage_data.files, file_entry)
      end
    end
  end

  return coverage_data
end

return M
