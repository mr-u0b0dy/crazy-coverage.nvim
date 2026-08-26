-- Python coverage.py parser and converter
local M = {}

local utils = require("crazy-coverage.utils")
local json_utils = require("crazy-coverage.parser.json")

--- Normalize path by resolving .. and . segments.
---@param path string
---@return string|nil
local function normalize_path(path)
  return utils.normalize_path(path)
end

---@param source_path string|nil
---@param coverage_dir string
---@param project_root string|nil
---@return string|nil
local function resolve_source_path(source_path, coverage_dir, project_root)
  if not source_path or source_path == "" then
    return nil
  end

  if source_path:sub(1, 1) == "/" then
    return normalize_path(source_path)
  end

  local relative_path = source_path:gsub("^%./", "")
  local parent_dir = vim.fn.fnamemodify(coverage_dir, ":p:h:h")
  local candidates = {
    coverage_dir .. "/" .. relative_path,
  }

  if project_root and project_root ~= "" then
    table.insert(candidates, project_root .. "/" .. relative_path)
  end

  if parent_dir and parent_dir ~= coverage_dir then
    table.insert(candidates, parent_dir .. "/" .. relative_path)
  end

  for _, candidate in ipairs(candidates) do
    local normalized = normalize_path(candidate)
    if normalized and vim.fn.filereadable(normalized) == 1 then
      return normalized
    end
  end

  if project_root and project_root ~= "" then
    return normalize_path(project_root .. "/" .. relative_path)
  end

  if parent_dir and parent_dir ~= "" then
    return normalize_path(parent_dir .. "/" .. relative_path)
  end

  return normalize_path(coverage_dir .. "/" .. relative_path)
end

---@return string|nil
local function find_coverage_command()
  if vim.fn.executable("coverage") == 1 then
    return "coverage"
  end

  if vim.fn.executable("python3") == 1 then
    return "python3 -m coverage"
  end

  return nil
end

---@param coverage_file string
---@return string|nil
local function convert_coverage_db_to_json(coverage_file)
  local command = find_coverage_command()
  if not command then
    vim.notify("coverage.py command not found. Install coverage or python3 with the coverage package.", vim.log.levels.ERROR)
    return nil
  end

  local json_file = vim.fn.tempname() .. ".json"
  local cmd = string.format(
    "%s json -o %s --data-file=%s --pretty-print --quiet",
    command,
    vim.fn.shellescape(json_file),
    vim.fn.shellescape(coverage_file)
  )

  local result = vim.fn.system(cmd)
  if vim.v.shell_error ~= 0 then
    vim.notify(string.format("coverage.py json export failed: %s", result), vim.log.levels.ERROR)
    pcall(os.remove, json_file)
    return nil
  end

  if not utils.file_exists(json_file) then
    vim.notify("coverage.py did not generate a JSON report", vim.log.levels.ERROR)
    return nil
  end

  return json_file
end

---@param file_data table
---@return table
local function collect_branches(file_data)
  local branches = {}
  local branch_counters = {}

  local function next_branch_id(line_num)
    local current = branch_counters[line_num] or 0
    current = current + 1
    branch_counters[line_num] = current
    return current
  end

  local function add_branch(branch, hits)
    local line_num
    if type(branch) == "table" then
      line_num = tonumber(branch.line or branch[1])
    end

    if line_num then
      table.insert(branches, {
        line = line_num,
        id = next_branch_id(line_num),
        hits = hits,
      })
    end
  end

  for _, branch in ipairs(file_data.executed_branches or {}) do
    add_branch(branch, 1)
  end

  for _, branch in ipairs(file_data.missing_branches or {}) do
    add_branch(branch, 0)
  end

  table.sort(branches, function(a, b)
    if a.line == b.line then
      return a.id < b.id
    end
    return a.line < b.line
  end)

  return branches
end

---@param file_data table
---@return table
local function collect_lines(file_data)
  local line_hits = {}

  for _, line_num in ipairs(file_data.executed_lines or {}) do
    local number = tonumber(line_num)
    if number then
      line_hits[number] = 1
    end
  end

  for _, line_num in ipairs(file_data.missing_lines or {}) do
    local number = tonumber(line_num)
    if number and line_hits[number] == nil then
      line_hits[number] = 0
    end
  end

  local lines = {}
  for line_num, hits in pairs(line_hits) do
    table.insert(lines, {
      line = line_num,
      hits = hits,
    })
  end

  table.sort(lines, function(a, b)
    return a.line < b.line
  end)

  return lines
end

---@param json_data table
---@param file_path string
---@param project_root string|nil
---@return table|nil
local function parse_python_json(json_data, file_path, project_root)
  if not json_data or type(json_data.files) ~= "table" then
    return nil
  end

  local coverage_dir = vim.fn.fnamemodify(file_path, ":p:h")
  local coverage_data = {}

  for source_path, file_data in pairs(json_data.files) do
    if type(file_data) == "table" then
      local resolved_path = resolve_source_path(source_path, coverage_dir, project_root)
      if resolved_path then
        local file_entry = json_utils.new_file_entry("python_coverage")
        file_entry.lines = collect_lines(file_data)
        file_entry.branches = collect_branches(file_data)
        json_utils.sort_lines(file_entry)
        coverage_data[resolved_path] = file_entry
      end
    end
  end

  return coverage_data
end

--- Parse coverage.py JSON output or convert a .coverage database first.
---@param file_path string
---@param project_root string|nil
---@return table|nil
function M.parse(file_path, project_root)
  if not file_path or file_path == "" then
    return nil
  end

  local parse_path = file_path
  local temporary_json

  if file_path:match("%.coverage$") or file_path:match("^%.coverage%.") then
    temporary_json = convert_coverage_db_to_json(file_path)
    if not temporary_json then
      return nil
    end
    parse_path = temporary_json
  end

  local json_data = json_utils.read(parse_path)
  if temporary_json then
    pcall(os.remove, temporary_json)
  end

  if not json_data then
    return nil
  end

  return parse_python_json(json_data, file_path, project_root)
end

return M