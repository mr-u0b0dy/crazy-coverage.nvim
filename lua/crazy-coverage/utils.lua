-- Utility functions for the coverage plugin
local M = {}

--- Check whether any scanned lines contain all of the expected JSON markers.
---@param lines string[]|nil
---@param markers string[]
---@return boolean
local function lines_contain_markers(lines, markers)
  if not lines or #lines == 0 then
    return false
  end

  for _, marker in ipairs(markers) do
    local found = false
    for _, line in ipairs(lines) do
      if line and line:match(marker) then
        found = true
        break
      end
    end
    if not found then
      return false
    end
  end

  return true
end

--- Normalize file path to absolute path, resolving .. and . segments
---@param path string
---@return string|nil
function M.normalize_path(path)
  if not path or path == "" then
    return nil
  end

  -- Use vim.fn.fnamemodify to get absolute path
  local normalized = vim.fn.fnamemodify(path, ":p")
  if normalized == "" then
    return nil
  end

  -- Manually resolve .. and . segments (important for non-existent files)
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

--- Read file contents
---@param file_path string
---@return string[]|nil
function M.read_file(file_path)
  if not file_path or file_path == "" then
    return nil
  end

  if not M.file_exists(file_path) then
    return nil
  end

  local ok, result = pcall(vim.fn.readfile, file_path)
  return ok and result or nil
end

--- Read only a prefix of a file (line-based)
---@param file_path string
---@param max_lines number|nil
---@return string[]|nil
function M.read_file_prefix(file_path, max_lines)
  if not file_path or file_path == "" then
    return nil
  end

  if not M.file_exists(file_path) then
    return nil
  end

  local limit = max_lines or 10
  local ok, result = pcall(vim.fn.readfile, file_path, "", limit)
  return ok and result or nil
end

--- Detect coverage format based on file extension and content
---@param file_path string
---@return string|nil -- 'lcov', 'llvm_json', 'cobertura', 'gcov', 'llvm_profdata', 'go_coverprofile', or nil
local function is_go_coverprofile(lines)
  if not lines or #lines < 1 then
    return false
  end

  local header = lines[1]
  if not header or not header:match("^mode:%s*[%a_]+$") then
    return false
  end

  -- Track whether we saw any non-empty lines and any valid record lines
  local has_nonempty_after_header = false
  local has_valid_record = false

  for i = 2, #lines do
    local line = lines[i]
    -- Treat lines with any non-whitespace as non-empty
    if line and line:match("%S") then
      has_nonempty_after_header = true
      if line:match("^.+:%d+%.%d+,%d+%.%d+%s+%d+%s+%d+$") then
        has_valid_record = true
      end
    end
  end

  -- Valid if we have at least one record, or if the file is header-only
  if has_valid_record or not has_nonempty_after_header then
    return true
  end
  return false
end

function M.detect_format(file_path)
  if not file_path or file_path == "" then
    return nil
  end

  local ext = file_path:match("%.([^.]+)$")

  if ext == "info" or ext == "lcov" then
    return "lcov"
  elseif ext == "gcda" or ext == "gcno" then
    return "gcov"
  elseif ext == "profdata" then
    return "llvm_profdata"
  elseif ext == "xml" then
    return "cobertura"
  end

  local lines
  local function get_lines()
    if lines == nil then
      lines = M.read_file_prefix(file_path, 10)
    end
    return lines
  end

  local prefix_lines = get_lines()
  if is_go_coverprofile(prefix_lines) then
    return "go_coverprofile"
  end

  if ext == "json" then
    -- Reuse already-read prefix lines instead of re-reading the file.
    if lines_contain_markers(prefix_lines, { '"traces"', '"functions"' }) then
      return "tarpaulin"
    elseif lines_contain_markers(prefix_lines, { '"version"', '"data"' }) then
      return "llvm_json"
    end
    return "llvm_json" -- Default JSON to LLVM JSON
  end

  -- Try content-based detection for text formats
  if prefix_lines and #prefix_lines > 0 then
    local first_line = prefix_lines[1]
    if first_line:match("^TN:") or first_line:match("^FN:") or first_line:match("^DA:") then
      return "lcov"
    elseif first_line:match("^{") then
      return "llvm_json"
    end
  end

  return nil
end

--- Check if file exists
---@param file_path string
---@return boolean
function M.file_exists(file_path)
  return vim.fn.filereadable(file_path) == 1
end

--- Get buffer by file path
---@param file_path string
---@return number|nil -- buffer handle or nil if not open
function M.get_buffer_by_path(file_path)
  if not file_path or file_path == "" then
    return nil
  end

  local config = require("crazy-coverage.config")
  local normalized_path = M.normalize_path(file_path)
  if not normalized_path then
    if config.debug_notifications then
      vim.notify(string.format("GET_BUF: Failed to normalize: %s", file_path), vim.log.levels.DEBUG)
    end
    return nil
  end

  if config.debug_notifications then
    vim.notify(string.format("GET_BUF: Looking for normalized: %s", normalized_path), vim.log.levels.DEBUG)
  end

  for _, buf in ipairs(vim.api.nvim_list_bufs()) do
    if vim.api.nvim_buf_is_valid(buf) and vim.api.nvim_buf_is_loaded(buf) then
      local buf_path = vim.api.nvim_buf_get_name(buf)
      if buf_path and buf_path ~= "" then
        local buf_normalized = M.normalize_path(buf_path)
        if config.debug_notifications then
          vim.notify(string.format("GET_BUF:   [buf %d] checking: %s", buf, buf_normalized or "(failed to normalize)"), vim.log.levels.DEBUG)
        end
        if buf_normalized == normalized_path then
          if config.debug_notifications then
            vim.notify(string.format("GET_BUF: ✓ MATCH! buf=%d", buf), vim.log.levels.DEBUG)
          end
          return buf
        end
      end
    end
  end

  if config.debug_notifications then
    vim.notify(string.format("GET_BUF: ✗ No matching buffer found"), vim.log.levels.DEBUG)
  end
  return nil
end

--- Parse JSON string
---@param json_str string
---@return table|nil
function M.parse_json(json_str)
  local ok, result = pcall(vim.fn.json_decode, json_str)
  return ok and result or nil
end

--- Encode table to JSON
---@param tbl table
---@return string
function M.to_json(tbl)
  return vim.fn.json_encode(tbl)
end

return M
