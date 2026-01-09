-- LLVM JSON format parser
local M = {}
local utils = require("crazy-coverage.utils")

--- Normalize path by resolving .. and . segments
---@param path string
---@return string
local function normalize_path(path)
  -- Try vim.fn.fnamemodify first
  local normalized = vim.fn.fnamemodify(path, ":p")
  
  -- If the path doesn't exist, manually resolve .. segments
  local parts = {}
  for part in normalized:gmatch("[^/]+") do
    if part == ".." then
      table.remove(parts)
    elseif part ~= "." then
      table.insert(parts, part)
    end
  end
  
  return "/" .. table.concat(parts, "/")
end

--- Parse LLVM JSON format
---@param file_path string
---@param project_root string|nil -- Project root for better path resolution
---@return table|nil -- CoverageData model or nil on error
function M.parse(file_path, project_root)
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

  -- Use coverage file directory as base for relative path resolution
  -- Relative paths in coverage files are relative to the coverage file location
  local coverage_dir = vim.fn.fnamemodify(file_path, ":p:h")
  
  -- Project root can be used for context, but coverage file directory is the base
  if not project_root then
    project_root = vim.fn.fnamemodify(file_path, ":p:h:h")
  end

  local coverage_data = {
    files = {},
  }

  -- LLVM JSON structure: { data: [{ files: [...] }] }
  for _, record in ipairs(json_data.data) do
    if record.files then
      for _, file_data in ipairs(record.files) do
        -- Resolve relative paths to absolute paths  
        local file_path = file_data.filename
        if file_path then
          -- If path is relative, make it absolute relative to coverage file directory
          if file_path:sub(1, 1) ~= "/" then
            file_path = coverage_dir .. "/" .. file_path
          end
          -- Normalize to absolute path (resolve .. and .)
          file_path = normalize_path(file_path)
        end
        
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
