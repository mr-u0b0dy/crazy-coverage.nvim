-- Go coverprofile parser
local M = {}
local utils = require("crazy-coverage.utils")

--- Extract module name from go.mod file
---@param path_to_mod string Path to directory containing go.mod
---@return string|nil  Module name (e.g., "example.com/crazy-coverage-go")
local function extract_module_name(path_to_mod)
  if not path_to_mod or not vim.fn.isdirectory(path_to_mod) == 1 then
    return nil
  end

  local mod_file = path_to_mod .. "/go.mod"
  if vim.fn.filereadable(mod_file) ~= 1 then
    return nil
  end

  local lines = utils.read_file(mod_file)
  if not lines or #lines == 0 then
    return nil
  end

  for _, line in ipairs(lines) do
    if line and line:match("^module%s+") then
      local module_name = line:match("^module%s+(.+)$")
      if module_name then
        return module_name:gsub("%s+$", "") -- trim trailing whitespace
      end
    end
  end

  return nil
end

--- Extract relative path from module-qualified Go path
--- E.g., "example.com/crazy-coverage-go/main.go" -> "main.go"
--- Or "example.com/crazy-coverage-go/pkg/util.go" -> "pkg/util.go"
---@param source_path string  Full path from coverage file (may include module)
---@param module_name string|nil  Module name to strip
---@return string  Relative path (with module stripped if applicable)
local function extract_relative_path(source_path, module_name)
  if not source_path or source_path == "" then
    return source_path
  end

  -- If path already starts with ./, it's already relative
  if source_path:sub(1, 2) == "./" or source_path:sub(1, 1) == "/" then
    return source_path
  end

  -- If we have a module name, try to strip it
  if module_name and module_name ~= "" then
    local pattern = "^" .. module_name:gsub("[%^%$%%%.%[%]%*%+%-%?]", "%%%1") .. "/"
    if source_path:match(pattern) then
      return source_path:gsub(pattern, "")
    end
  end

  -- No module prefix to strip, return as-is (might be relative already)
  return source_path
end

--- Resolve a source path from coverage data to an absolute normalized path.
---@param source_path string
---@param coverage_dir string
---@param project_root string|nil
---@param module_name string|nil
---@return string|nil
local function resolve_source_path(source_path, coverage_dir, project_root, module_name)
  if not source_path or source_path == "" then
    return nil
  end

  -- Extract relative path (strip module prefix if present)
  local relative_path = extract_relative_path(source_path, module_name)

  -- Absolute path: return as-is
  if relative_path:sub(1, 1) == "/" then
    return utils.normalize_path(relative_path)
  end

  -- Try project root first (Go sources are normally in project root)
  if project_root and project_root ~= "" then
    local from_root = utils.normalize_path(project_root .. "/" .. relative_path)
    if vim.fn.filereadable(from_root) == 1 then
      return from_root
    end
  end

  -- Try coverage directory (fallback)
  local from_coverage_dir = utils.normalize_path(coverage_dir .. "/" .. relative_path)
  if vim.fn.filereadable(from_coverage_dir) == 1 then
    return from_coverage_dir
  end

  -- Last resort: try parent directory of coverage_dir (go builds often have build/)
  local parent_dir = vim.fn.fnamemodify(coverage_dir, ":p:h:h")
  if parent_dir and parent_dir ~= coverage_dir then
    local from_parent = utils.normalize_path(parent_dir .. "/" .. relative_path)
    if vim.fn.filereadable(from_parent) == 1 then
      return from_parent
    end
  end

  -- Return normalized project root version if available, else normalized coverage dir version
  if project_root and project_root ~= "" then
    return utils.normalize_path(project_root .. "/" .. relative_path)
  end

  return utils.normalize_path(coverage_dir .. "/" .. relative_path)
end

--- Ensure a file entry exists in output map and return it.
---@param coverage_data table
---@param abs_path string
---@return table
local function ensure_file_entry(coverage_data, abs_path)
  local entry = coverage_data[abs_path]
  if entry then
    return entry
  end

  entry = {
    lines = {},
    branches = {},
    functions = {},
    source_format = "go_coverprofile",
  }
  coverage_data[abs_path] = entry
  return entry
end

--- Parse Go coverprofile format.
--- Expected lines:
---   mode: set|count|atomic
---   path/to/file.go:10.2,12.9 2 1
---@param file_path string
---@param project_root string|nil
---@return table|nil
function M.parse(file_path, project_root)
  if not utils.file_exists(file_path) then
    return nil
  end

  local lines = utils.read_file(file_path)
  if not lines or #lines == 0 then
    return nil
  end

  local header = lines[1]
  if not header or not header:match("^mode:%s*[%a_]+$") then
    return nil
  end

  local coverage_dir = vim.fn.fnamemodify(file_path, ":p:h")
  if not project_root then
    project_root = vim.fn.fnamemodify(file_path, ":p:h:h")
  end

  -- Extract module name from go.mod for path resolution
  local module_name = extract_module_name(project_root)

  local coverage_data = {}
  local line_aggregates = {}

  for i = 2, #lines do
    local line = lines[i]
    if line and line ~= "" then
      local source_path, start_line, _start_col, end_line, _end_col, _num_stmt, count =
        line:match("^(.+):(%d+)%.(%d+),(%d+)%.(%d+)%s+(%d+)%s+(%d+)$")

      if source_path and start_line and end_line and count then
        local abs_path = resolve_source_path(source_path, coverage_dir, project_root, module_name)
        if abs_path then
          local file_entry = ensure_file_entry(coverage_data, abs_path)
          local per_file = line_aggregates[abs_path]
          if not per_file then
            per_file = {}
            line_aggregates[abs_path] = per_file
          end

          local start_num = tonumber(start_line)
          local end_num = tonumber(end_line)
          local hit_count = tonumber(count) or 0
          if start_num and end_num then
            for line_num = start_num, end_num do
              per_file[line_num] = (per_file[line_num] or 0) + hit_count
            end
          end

          -- Retain reference in case future format versions include branch/function data.
          file_entry.branches = file_entry.branches or {}
          file_entry.functions = file_entry.functions or {}
        end
      end
    end
  end

  for abs_path, by_line in pairs(line_aggregates) do
    local file_entry = coverage_data[abs_path]
    for line_num, hit_count in pairs(by_line) do
      table.insert(file_entry.lines, {
        line = line_num,
        hits = hit_count,
      })
    end

    table.sort(file_entry.lines, function(a, b)
      return a.line < b.line
    end)
  end

  return coverage_data
end

return M