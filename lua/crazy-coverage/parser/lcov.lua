-- LCOV format parser
local M = {}
local utils = require("crazy-coverage.utils")

--- Normalize path by resolving .. and . segments
---@param path string
---@return string
local function normalize_path(path)
  return utils.normalize_path(path)
end

--- Extract module name from go.mod file when available.
---@param project_root string|nil
---@return string|nil
local function extract_module_name(project_root)
  if not project_root or project_root == "" then
    return nil
  end

  if vim.fn.isdirectory(project_root) ~= 1 then
    return nil
  end

  local mod_file = project_root .. "/go.mod"
  if vim.fn.filereadable(mod_file) ~= 1 then
    return nil
  end

  local mod_lines = utils.read_file(mod_file)
  if not mod_lines then
    return nil
  end

  for _, mod_line in ipairs(mod_lines) do
    if mod_line and mod_line:match("^module%s+") then
      local module_name = mod_line:match("^module%s+(.+)$")
      if module_name then
        return module_name:gsub("%s+$", "")
      end
    end
  end

  return nil
end

--- Find a directory containing go.mod by walking up parent directories.
---@param start_dir string|nil
---@param max_levels number|nil
---@return string|nil
local function find_go_module_root(start_dir, max_levels)
  if not start_dir or start_dir == "" then
    return nil
  end

  local levels = max_levels or 6
  local current = normalize_path(start_dir)

  for _ = 0, levels do
    if not current or current == "" then
      break
    end

    local mod_file = current .. "/go.mod"
    if vim.fn.filereadable(mod_file) == 1 then
      return current
    end

    local parent = vim.fn.fnamemodify(current, ":h")
    if not parent or parent == "" or parent == current then
      break
    end
    current = parent
  end

  return nil
end

--- Strip module prefix from module-qualified source paths.
---@param source_path string
---@param module_name string|nil
---@return string
local function strip_module_prefix(source_path, module_name)
  if not source_path or source_path == "" then
    return source_path
  end

  if source_path:sub(1, 1) == "/" then
    return source_path
  end

  if not module_name or module_name == "" then
    return source_path
  end

  local escaped = module_name:gsub("[%^%$%%%.%[%]%*%+%-%?]", "%%%1")
  local pattern = "^" .. escaped .. "/"
  if source_path:match(pattern) then
    return source_path:gsub(pattern, "")
  end

  return source_path
end

---@param relative_path string
---@return string[]
local function build_relative_candidates(relative_path)
  local candidates = {}
  local seen = {}

  local function add_candidate(path)
    if not path or path == "" or seen[path] then
      return
    end
    seen[path] = true
    table.insert(candidates, path)
  end

  add_candidate(relative_path)
  add_candidate(relative_path:gsub("^%./", ""))

  -- Some converters emit project-prefixed SF paths (e.g. coverage-examples/go/main.go).
  -- Progressively drop leading segments to recover the source-relative suffix.
  local segments = {}
  for segment in relative_path:gmatch("[^/]+") do
    table.insert(segments, segment)
  end
  for i = 2, #segments do
    add_candidate(table.concat(segments, "/", i))
  end

  return candidates
end

---@param coverage_dir string
---@param project_root string|nil
---@param module_root string|nil
---@return string[]
local function build_base_dirs(coverage_dir, project_root, module_root)
  local base_dirs = {}
  if module_root and module_root ~= "" then
    table.insert(base_dirs, module_root)
  end
  if project_root and project_root ~= "" then
    table.insert(base_dirs, project_root)
  end
  table.insert(base_dirs, coverage_dir)

  local parent_dir = vim.fn.fnamemodify(coverage_dir, ":p:h:h")
  if parent_dir and parent_dir ~= coverage_dir then
    table.insert(base_dirs, parent_dir)
  end

  return base_dirs
end

---@param base_dirs string[]
---@param relative_candidates string[]
---@return string|nil
local function find_existing_candidate(base_dirs, relative_candidates)
  for _, base_dir in ipairs(base_dirs) do
    for _, relative_path in ipairs(relative_candidates) do
      local candidate = normalize_path(base_dir .. "/" .. relative_path)
      if candidate and vim.fn.filereadable(candidate) == 1 then
        return candidate
      end
    end
  end

  return nil
end

--- Resolve LCOV SF path to normalized absolute path.
---@param source_path string
---@param coverage_dir string
---@param project_root string|nil
---@param module_name string|nil
---@param module_root string|nil
---@return string|nil
local function resolve_source_path(source_path, coverage_dir, project_root, module_name, module_root)
  if not source_path or source_path == "" then
    return nil
  end

  if source_path:sub(1, 1) == "/" then
    return normalize_path(source_path)
  end

  local relative_path = strip_module_prefix(source_path, module_name)
  local relative_candidates = build_relative_candidates(relative_path)
  local base_dirs = build_base_dirs(coverage_dir, project_root, module_root)
  local resolved = find_existing_candidate(base_dirs, relative_candidates)
  if resolved then
    return resolved
  end

  if module_root and module_root ~= "" then
    return normalize_path(module_root .. "/" .. relative_path)
  end

  if project_root and project_root ~= "" then
    return normalize_path(project_root .. "/" .. relative_path)
  end

  return normalize_path(coverage_dir .. "/" .. relative_path)
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
---@param line_hits table<number, number>
local function parse_line_coverage(line, line_hits)
  local parts = split_string(line:sub(4), ",")
  if #parts >= 2 then
    local line_num = tonumber(parts[1])
    local hit_count = tonumber(parts[2])
    if line_num and hit_count ~= nil then
      -- Keep the highest observed hit count for duplicate DA lines.
      local prev = line_hits[line_num]
      if prev == nil or hit_count > prev then
        line_hits[line_num] = hit_count
      end
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
    local block_id = parts[2]
    local branch_id = parts[3]
    local taken_str = parts[4]
    
    if line_num and block_id and block_id ~= "" and branch_id and branch_id ~= "" then
      -- Handle "-" as 0 hits (branch not taken / not instrumented)
      local taken = 0
      if taken_str ~= "-" then
        taken = tonumber(taken_str) or 0
      end
      
      table.insert(current_file.branches, {
        line = line_num,
        id = tonumber(branch_id) or branch_id,
        block_id = tonumber(block_id) or block_id,
        branch_id = tonumber(branch_id) or branch_id,
        hits = taken,
      })
    end
  end
end

---@return table
local function new_file_entry()
  return {
    lines = {},
    branches = {},
    functions = {},
  }
end

---@param current_file table|nil
---@param line_hits table<number, number>|nil
local function flush_line_hits(current_file, line_hits)
  if not current_file or not line_hits then
    return
  end

  for line_num, hits in pairs(line_hits) do
    table.insert(current_file.lines, {
      line = line_num,
      hits = hits,
    })
  end

  table.sort(current_file.lines, function(a, b)
    return a.line < b.line
  end)
end

---@param line string
---@param current_file table
---@param functions_map table<string, table>
local function parse_function_definition(line, current_file, functions_map)
  local parts = split_string(line:sub(4), ",")
  if #parts < 2 then
    return
  end

  local line_num = tonumber(parts[1])
  local func_name = parts[2]
  if not line_num or not func_name then
    return
  end

  local entry = functions_map[func_name]
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

---@param line string
---@param current_file table
---@param functions_map table<string, table>
local function parse_function_hits(line, current_file, functions_map)
  local parts = split_string(line:sub(6), ",")
  if #parts < 2 then
    return
  end

  local hit_count = tonumber(parts[1]) or 0
  local func_name = parts[2]
  if not func_name then
    return
  end

  local entry = functions_map[func_name]
  if not entry then
    entry = {
      line = nil,
      name = func_name,
      hit_count = hit_count,
      covered = hit_count > 0,
    }
    functions_map[func_name] = entry
    table.insert(current_file.functions, entry)
  else
    entry.hit_count = hit_count
    entry.covered = hit_count > 0
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
    -- Prefer inferred module root from coverage location before generic fallbacks.
    local inferred_root = find_go_module_root(coverage_dir, 8)
    if inferred_root then
      project_root = inferred_root
    else
      -- Fall back to the parent of coverage_dir (one level above the directory that
      -- contains the coverage file). Using `:p:h:h:h` (grandparent of the file) can
      -- overshoot to "/" for layouts like <root>/coverage/coverage.lcov, so we go
      -- only one level above coverage_dir and guard against reaching the fs root.
      local parent_dir = vim.fn.fnamemodify(coverage_dir, ":h")
      if parent_dir and parent_dir ~= "/" and parent_dir ~= coverage_dir then
        project_root = parent_dir
      else
        project_root = coverage_dir
      end
    end
  end

  -- Guard against project_root resolving to the filesystem root, which would cause
  -- unresolved relative SF paths to normalize to "/<file>" instead of a meaningful path.
  if project_root == "/" then
    project_root = coverage_dir
  end

  local module_root = find_go_module_root(project_root, 8)
  if not module_root then
    module_root = find_go_module_root(coverage_dir, 8)
  end

  local module_name = extract_module_name(module_root or project_root)

  -- Return format: {file_path: {lines: [...], branches: [...]}}
  local coverage_data = {}

  local current_file = nil
  local current_file_line_hits = nil
  local functions_map = nil

  for _, line in ipairs(lines) do
    if line:match("^SF:") then
      local file_name = line:sub(4)
      local file_path = resolve_source_path(
        file_name,
        coverage_dir,
        project_root,
        module_name,
        module_root
      )

      if file_path and file_path ~= "" then
        current_file = new_file_entry()
        coverage_data[file_path] = current_file
        current_file_line_hits = {}
        functions_map = {}
      else
        -- Skip SF records that cannot be resolved
        current_file = nil
        current_file_line_hits = nil
        functions_map = nil
      end

    elseif line:match("^DA:") and current_file and current_file_line_hits then
      parse_line_coverage(line, current_file_line_hits)

    elseif line:match("^BRDA:") and current_file then
      parse_branch_coverage(line, current_file)

    elseif line:match("^FN:") and current_file and functions_map then
      parse_function_definition(line, current_file, functions_map)

    elseif line:match("^FNDA:") and current_file and functions_map then
      parse_function_hits(line, current_file, functions_map)

    elseif line == "end_of_record" then
      flush_line_hits(current_file, current_file_line_hits)
      current_file = nil
      current_file_line_hits = nil
      functions_map = nil
    end
  end

  flush_line_hits(current_file, current_file_line_hits)

  return coverage_data
end

return M
