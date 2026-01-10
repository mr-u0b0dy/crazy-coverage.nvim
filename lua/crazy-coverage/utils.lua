-- Utility functions for the coverage plugin
local M = {}

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

--- Detect coverage format based on file extension and content
---@param file_path string
---@return string|nil -- 'lcov', 'llvm_json', 'cobertura', 'gcov', 'llvm_profdata', or nil
function M.detect_format(file_path)
  local ext = file_path:match("%.([^.]+)$")

  if ext == "info" or ext == "lcov" then
    return "lcov"
  elseif ext == "json" then
    -- Check if it's LLVM JSON format
    local lines = M.read_file(file_path)
    if lines and #lines > 0 then
      local first_line = lines[1]
      if first_line:match('"version"') and first_line:match('"data"') then
        return "llvm_json"
      end
    end
    return "llvm_json" -- Default JSON to LLVM JSON
  elseif ext == "xml" then
    return "cobertura"
  elseif ext == "gcda" or ext == "gcno" then
    return "gcov"
  elseif ext == "profdata" then
    return "llvm_profdata"
  end

  -- Try content-based detection for text formats
  local lines = M.read_file(file_path)
  if lines and #lines > 0 then
    local first_line = lines[1]
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
  
  local normalized_path = M.normalize_path(file_path)
  if not normalized_path then
    vim.notify(string.format("GET_BUF: Failed to normalize: %s", file_path), vim.log.levels.DEBUG)
    return nil
  end
  
  vim.notify(string.format("GET_BUF: Looking for normalized: %s", normalized_path), vim.log.levels.DEBUG)
  
  for _, buf in ipairs(vim.api.nvim_list_bufs()) do
    if vim.api.nvim_buf_is_valid(buf) and vim.api.nvim_buf_is_loaded(buf) then
      local buf_path = vim.api.nvim_buf_get_name(buf)
      if buf_path and buf_path ~= "" then
        local buf_normalized = M.normalize_path(buf_path)
        vim.notify(string.format("GET_BUF:   [buf %d] checking: %s", buf, buf_normalized or "(failed to normalize)"), vim.log.levels.DEBUG)
        if buf_normalized == normalized_path then
          vim.notify(string.format("GET_BUF: ✓ MATCH! buf=%d", buf), vim.log.levels.DEBUG)
          return buf
        end
      end
    end
  end
  
  vim.notify(string.format("GET_BUF: ✗ No matching buffer found"), vim.log.levels.DEBUG)
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
