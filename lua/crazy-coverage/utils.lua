-- Utility functions for the coverage plugin
local M = {}

--- Normalize file path to absolute path
---@param path string
---@return string|nil
function M.normalize_path(path)
  if not path or path == "" then
    return nil
  end
  
  if path:sub(1, 1) == "/" then
    return path
  end
  
  local normalized = vim.fn.fnamemodify(path, ":p")
  return normalized ~= "" and normalized or nil
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

  if ext == "info" then
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
    return nil
  end
  
  for _, buf in ipairs(vim.api.nvim_list_bufs()) do
    if vim.api.nvim_buf_is_valid(buf) and vim.api.nvim_buf_is_loaded(buf) then
      local buf_path = vim.api.nvim_buf_get_name(buf)
      if buf_path and buf_path ~= "" then
        local buf_normalized = M.normalize_path(buf_path)
        if buf_normalized == normalized_path then
          return buf
        end
      end
    end
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
