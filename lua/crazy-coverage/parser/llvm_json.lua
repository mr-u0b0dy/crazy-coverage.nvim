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
---@return table|nil -- Coverage data keyed by file path, or nil on error
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

  -- Return format: {file_path: {lines: [...], branches: [...]}}
  local coverage_data = {}

  -- LLVM JSON structure: { data: [{ files: [...] }] }
  for _, record in ipairs(json_data.data) do
    if record.files then
      for _, file_data in ipairs(record.files) do
        -- Resolve relative paths to absolute paths
        local source_file_path = file_data.filename
        if source_file_path then
          -- If path is relative, make it absolute relative to coverage file directory
          if source_file_path:sub(1, 1) ~= "/" then
            source_file_path = coverage_dir .. "/" .. source_file_path
          end
          -- Normalize to absolute path (resolve .. and .)
          source_file_path = normalize_path(source_file_path)
        end
        
        local file_entry = {
          lines = {},
          branches = {},
        }

        -- Try parsing Format A: "lines" array (standard llvm-cov export output)
        if file_data.lines and #file_data.lines > 0 then
          for _, line_data in ipairs(file_data.lines) do
            local line_num = line_data.line_number
            local count = line_data.count or 0
            
            if line_num then
              table.insert(file_entry.lines, {
                line = line_num,
                hits = count,
              })
              
              -- Parse regions as branch coverage if present
              if line_data.regions and #line_data.regions > 0 then
                for region_idx, region in ipairs(line_data.regions) do
                  local region_count = region.count or 0
                  table.insert(file_entry.branches, {
                    line = line_num,
                    id = region_idx,
                    hits = region_count,
                  })
                end
              end
            end
          end
          
          -- Log success if debug is enabled
          local config = require("crazy-coverage.config")
          if config.debug_notifications then
            vim.notify(
              string.format("LLVM JSON: Parsed %d lines (Format A) from %s", 
                #file_entry.lines, source_file_path),
              vim.log.levels.DEBUG
            )
          end
        -- Fallback to Format B: "segments" array (compact representation)
        elseif file_data.segments and #file_data.segments > 0 then
          local line_coverage = {}  -- Map line_num -> max hit count
          local segment_idx = 0     -- Track segment index for region IDs
          
          for _, segment in ipairs(file_data.segments) do
            segment_idx = segment_idx + 1
            local line_num = segment[1]
            local col_start = segment[2]
            local count = segment[3] or 0
            local has_count = segment[4]
            local is_gap_region = segment[6]    -- Gap region (no code)
            
            -- Skip gap regions as they represent areas without code
            if is_gap_region then
              goto continue
            end
            
            -- Process segments that have execution counts - they're regions/branches!
            if line_num then
              -- Track line coverage (max hit count for the line)
              if has_count then
                if not line_coverage[line_num] or line_coverage[line_num] < count then
                  line_coverage[line_num] = count
                end
              end
              
              -- Add each segment as a branch/region entry
              -- This preserves fine-grained coverage data (column level)
              table.insert(file_entry.branches, {
                line = line_num,
                col = col_start,          -- Column position for location accuracy
                id = segment_idx,         -- Unique ID for this region
                hits = count,
              })
            end
            
            ::continue::
          end
          
          -- Convert line coverage map to sorted array
          for line_num, hit_count in pairs(line_coverage) do
            table.insert(file_entry.lines, {
              line = line_num,
              hits = hit_count,
            })
          end
          
          -- Sort by line number
          table.sort(file_entry.lines, function(a, b)
            return a.line < b.line
          end)
          
          -- Log success if debug is enabled
          local config = require("crazy-coverage.config")
          if config.debug_notifications then
            vim.notify(
              string.format("LLVM JSON: Parsed %d lines (Format B) and %d regions from %s", 
                #file_entry.lines, segment_idx, source_file_path),
              vim.log.levels.DEBUG
            )
          end
        end

        -- Parse branches (Format B compact array) - actual branch points
        -- These are more specific than segments and represent true branch coverage
        if file_data.branches and #file_data.branches > 0 then
          for idx, branch in ipairs(file_data.branches) do
            -- Branch format: [line, col, endLine, endCol, folded, count, ...]
            local line_num = branch[1]
            local count = branch[6] or 0
            
            if line_num then
              table.insert(file_entry.branches, {
                line = line_num,
                col = branch[2],          -- Column start for location
                end_col = branch[4],      -- Column end for location
                id = idx + 1000,          -- Offset ID to avoid collision with segment IDs
                hits = count,
                is_branch = true,         -- Mark as explicit branch for priority rendering
              })
            end
          end
        end

        if source_file_path then
          coverage_data[source_file_path] = file_entry
        end
      end
    end
  end

  return coverage_data
end

return M
