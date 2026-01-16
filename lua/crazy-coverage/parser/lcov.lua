-- LCOV format parser
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

--- Split string by delimiter
---@param str string
---@param delimiter string
---@return string[]
local function split_string(str, delimiter)
  if not str or str == "" then
    return {}
  end
  
  local parts = {}
  for part in string.gmatch(str, "[^" .. delimiter .. "]+") do
    table.insert(parts, part)
  end
  return parts
end

--- Parse a line coverage entry (DA line)
---@param line string
---@param current_file table
local function parse_line_coverage(line, current_file)
  local parts = split_string(line:sub(4), ",")
  if #parts >= 2 then
    local line_num = tonumber(parts[1])
    local hit_count = tonumber(parts[2])
    if line_num and hit_count ~= nil then
      table.insert(current_file.lines, {
        line = line_num,
        hits = hit_count,
      })
    end
  end
end

--- Parse a branch coverage entry (BRDA line)
--- Format: BRDA:line,block,branch,taken
---@param line string
---@param current_file table
local function parse_branch_coverage(line, current_file)
  local parts = split_string(line:sub(6), ",")
  if #parts >= 4 then
    local line_num = tonumber(parts[1])
    local block_id = tonumber(parts[2])
    local branch_id = tonumber(parts[3])
    local taken = tonumber(parts[4])
    if line_num and block_id ~= nil and branch_id ~= nil and taken ~= nil then
      table.insert(current_file.branches, {
        line = line_num,
        id = block_id * 100 + branch_id,
        hits = taken,
      })
    end
  end
end

--- Parse LCOV format (.info file)
---@param file_path string
---@param project_root string|nil -- Project root for better path resolution
---@return table|nil -- CoverageData model or nil on error
function M.parse(file_path, project_root)
  if not utils.file_exists(file_path) then
    return nil
  end

  local lines = utils.read_file(file_path)
  if not lines or #lines == 0 then
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

  local current_file = nil
  local current_file_path = nil
  local files_map = {}
  local functions_map = nil

  for _, line in ipairs(lines) do
    -- Parse source file declaration
    if line:match("^SF:") then
      local file_name = line:sub(4)
      -- Resolve relative paths to absolute paths
      local file_path = file_name
      if file_path:sub(1, 1) ~= "/" then
        file_path = coverage_dir .. "/" .. file_path
      end
      -- Normalize to absolute path (resolve .. and .)
      file_path = normalize_path(file_path)
      
      current_file_path = file_path
      current_file = {
        lines = {},
        branches = {},
        functions = {},
      }
      files_map[file_name] = current_file
      coverage_data[file_path] = current_file
      functions_map = {}
    end

    -- Parse line coverage
    if line:match("^DA:") and current_file then
      parse_line_coverage(line, current_file)
    end

    -- Parse branch coverage
    if line:match("^BRDA:") and current_file then
      parse_branch_coverage(line, current_file)
    end

    -- Parse function: FN:<line>,<name>
    if line:match("^FN:") and current_file then
      local parts = split_string(line:sub(4), ",")
      if #parts >= 2 then
        local line_num = tonumber(parts[1])
        local func_name = parts[2]
        if line_num and func_name then
          local entry = functions_map and functions_map[func_name]
          if not entry then
            entry = {
              line = line_num,
              name = func_name,
              hit_count = 0,
              covered = false,
            }
            functions_map[func_name] = entry
            table.insert(current_file.functions, entry)
          else
            entry.line = line_num
          end
        end
      end
    end

    -- Parse function execution count: FNDA:<hit_count>,<name>
    if line:match("^FNDA:") and current_file then
      local parts = split_string(line:sub(6), ",")
      if #parts >= 2 then
        local hit_count = tonumber(parts[1]) or 0
        local func_name = parts[2]
        if func_name then
          local entry = functions_map and functions_map[func_name]
          if not entry then
            -- Create entry if FNDA appears before FN
            entry = {
              line = nil,
              name = func_name,
              hit_count = hit_count,
              covered = hit_count > 0,
            }
            if functions_map then
              functions_map[func_name] = entry
            end
            table.insert(current_file.functions, entry)
          else
            entry.hit_count = hit_count
            entry.covered = hit_count > 0
          end
        end
      end
    end

    -- Parse end of file
    if line == "end_of_record" then
      current_file = nil
      functions_map = nil
    end
  end

  return coverage_data
end

return M
