-- Cobertura XML format parser
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

  local levels = max_levels or 8
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

--- Resolve Cobertura filename to normalized absolute path.
---@param source_path string
---@param coverage_dir string
---@param project_root string|nil
---@param module_name string|nil
---@param module_root string|nil
---@param source_roots string[]
---@return string|nil
local function resolve_source_path(source_path, coverage_dir, project_root, module_name, module_root, source_roots)
  if not source_path or source_path == "" then
    return nil
  end

  if source_path:sub(1, 1) == "/" then
    return normalize_path(source_path)
  end

  local relative_path = strip_module_prefix(source_path, module_name)
  local candidates = {}

  for _, root in ipairs(source_roots or {}) do
    if root and root ~= "" then
      table.insert(candidates, root .. "/" .. relative_path)
    end
  end

  if module_root and module_root ~= "" then
    table.insert(candidates, module_root .. "/" .. relative_path)
  end

  if project_root and project_root ~= "" then
    table.insert(candidates, project_root .. "/" .. relative_path)
  end

  table.insert(candidates, coverage_dir .. "/" .. relative_path)

  local parent_dir = vim.fn.fnamemodify(coverage_dir, ":p:h:h")
  if parent_dir and parent_dir ~= coverage_dir then
    table.insert(candidates, parent_dir .. "/" .. relative_path)
  end

  for _, candidate in ipairs(candidates) do
    local normalized = normalize_path(candidate)
    if normalized and vim.fn.filereadable(normalized) == 1 then
      return normalized
    end
  end

  if module_root and module_root ~= "" then
    return normalize_path(module_root .. "/" .. relative_path)
  end

  if project_root and project_root ~= "" then
    return normalize_path(project_root .. "/" .. relative_path)
  end

  return normalize_path(coverage_dir .. "/" .. relative_path)
end

--- Simple XML tag extractor (not a full XML parser)
---@param content string
---@param tag_name string
---@return table
local function extract_xml_nodes(content, tag_name)
  local nodes = {}
  local pattern = "<" .. tag_name .. "([^>]*)>([%s%S]-)</" .. tag_name .. ">"
  for attrs, inner in content:gmatch(pattern) do
    table.insert(nodes, { attrs = attrs, inner = inner })
  end
  return nodes
end

--- Extract self-closing XML tags like <tag attr="..."/>
---@param content string
---@param tag_name string
---@return table
local function extract_xml_self_closing(content, tag_name)
  local nodes = {}
  local pattern = "<" .. tag_name .. "([^>]*)/>"
  for attrs in content:gmatch(pattern) do
    table.insert(nodes, { attrs = attrs, inner = "" })
  end
  return nodes
end

--- Extract <class ... filename="..."> blocks and capture filename and inner content
---@param content string
---@return table
local function extract_xml_classes_with_filename(content)
  local nodes = {}
  local pos = 1
  while true do
    local s, e, filename = content:find("<class%s+[^>]-filename=\"([^\"]+)\"[^>]*>", pos)
    if not s then break end
    local close_s, close_e = content:find("</class>", e + 1)
    local inner = ""
    if close_s then
      inner = content:sub(e + 1, close_s - 1)
      pos = close_e + 1
    else
      pos = e + 1
    end
    table.insert(nodes, { filename = filename, inner = inner })
  end
  return nodes
end

--- Extract <source> nodes used by Cobertura to define source roots.
---@param content string
---@return string[]
local function extract_xml_sources(content)
  local sources = {}
  for source in content:gmatch("<source>([%s%S]-)</source>") do
    local trimmed = source:gsub("^%s+", ""):gsub("%s+$", "")
    if trimmed ~= "" then
      table.insert(sources, trimmed)
    end
  end
  return sources
end

--- Extract attribute from XML tag
---@param attrs string
---@param attr_name string
---@return string|nil
local function get_attr(attrs, attr_name)
  local pattern = attr_name .. '="([^"]*)"'
  local match = attrs:match(pattern)
  return match
end

---@param content string
---@return table
local function collect_class_nodes(content)
  local by_filename = extract_xml_classes_with_filename(content)
  if #by_filename > 0 then
    return by_filename
  end

  local nodes = {}
  for _, class_node in ipairs(extract_xml_nodes(content, "class")) do
    local filename = get_attr(class_node.attrs, "filename")
    if filename and filename ~= "" then
      table.insert(nodes, {
        filename = filename,
        inner = class_node.inner,
      })
    end
  end
  return nodes
end

---@param condition_coverage string|nil
---@return number|nil, number|nil
local function parse_condition_coverage(condition_coverage)
  if not condition_coverage or condition_coverage == "" then
    return nil, nil
  end

  local covered, total = condition_coverage:match("%((%d+)%/(%d+)%)")
  if not covered or not total then
    return nil, nil
  end

  return tonumber(covered), tonumber(total)
end

---@param current number|nil
---@param candidate number
---@return number
local function max_or_default(current, candidate)
  if current == nil or candidate > current then
    return candidate
  end
  return current
end

---@param target table<number, number>
---@param source table<number, number>
local function merge_line_hits(target, source)
  for line_num, hits in pairs(source) do
    target[line_num] = max_or_default(target[line_num], hits)
  end
end

---@param target table<number, table>
---@param source table<number, table>
local function merge_line_branches(target, source)
  for line_num, branches in pairs(source) do
    target[line_num] = target[line_num] or {}
    for branch_id, hits in pairs(branches) do
      target[line_num][branch_id] = max_or_default(target[line_num][branch_id], hits)
    end
  end
end

---@param inner_xml string
---@return table<number, number>, table<number, table>
local function parse_line_nodes(inner_xml)
  -- Parse only class-level <lines> block to avoid counting method-level duplicates.
  local class_inner = inner_xml:gsub("<methods[%s%S]-</methods>", "")
  local lines_section = class_inner:match("<lines>([%s%S]-)</lines>") or class_inner

  local line_nodes = extract_xml_nodes(lines_section, "line")
  local sc_nodes = extract_xml_self_closing(lines_section, "line")
  for _, n in ipairs(sc_nodes) do
    table.insert(line_nodes, n)
  end

  local line_hits = {}
  local line_branches = {}

  for _, line_node in ipairs(line_nodes) do
    local line_num = tonumber(get_attr(line_node.attrs, "number"))
    local hit_count = tonumber(get_attr(line_node.attrs, "hits")) or 0
    if line_num then
      local prev = line_hits[line_num]
      if prev == nil or hit_count > prev then
        line_hits[line_num] = hit_count
      end

      -- Preferred shape: explicit <branch ...> child nodes.
      local branch_nodes = extract_xml_nodes(line_node.inner, "branch")
      if #branch_nodes > 0 then
        line_branches[line_num] = line_branches[line_num] or {}
        for branch_idx, branch_node in ipairs(branch_nodes) do
          local branch_number = tonumber(get_attr(branch_node.attrs, "number")) or branch_idx
          local branch_taken = tonumber(get_attr(branch_node.attrs, "taken")) or 0
          line_branches[line_num][branch_number] = math.max(line_branches[line_num][branch_number] or 0, branch_taken)
        end
      else
        -- Common Cobertura shape: branch="true" condition-coverage="50% (1/2)"
        local is_branch_line = get_attr(line_node.attrs, "branch") == "true"
        local covered, total = parse_condition_coverage(get_attr(line_node.attrs, "condition-coverage"))
        if is_branch_line and covered and total and total > 0 then
          line_branches[line_num] = line_branches[line_num] or {}
          for branch_id = 0, total - 1 do
            local synthetic_hits = branch_id < covered and 1 or 0
            line_branches[line_num][branch_id] = math.max(line_branches[line_num][branch_id] or 0, synthetic_hits)
          end
        end
      end
    end
  end

  return line_hits, line_branches
end

---@param file_entry table
---@param line_hits table<number, number>
---@param line_branches table<number, table>
local function merge_file_entry(file_entry, line_hits, line_branches)
  local merged_line_hits = {}
  local merged_line_branches = {}

  for _, line_entry in ipairs(file_entry.lines) do
    merged_line_hits[line_entry.line] = max_or_default(merged_line_hits[line_entry.line], line_entry.hits or 0)
  end

  for _, branch_entry in ipairs(file_entry.branches) do
    local line_num = branch_entry.line
    if line_num ~= nil then
      merged_line_branches[line_num] = merged_line_branches[line_num] or {}
      local branch_id = branch_entry.id or 0
      merged_line_branches[line_num][branch_id] = max_or_default(
        merged_line_branches[line_num][branch_id],
        branch_entry.hits or 0
      )
    end
  end

  merge_line_hits(merged_line_hits, line_hits)
  merge_line_branches(merged_line_branches, line_branches)

  file_entry.lines = {}
  for line_num, hits in pairs(merged_line_hits) do
    table.insert(file_entry.lines, {
      line = line_num,
      hits = hits,
    })
  end

  table.sort(file_entry.lines, function(a, b)
    return a.line < b.line
  end)

  file_entry.branches = {}
  for line_num, branches in pairs(merged_line_branches) do
    for branch_id, hits in pairs(branches) do
      table.insert(file_entry.branches, {
        line = line_num,
        id = branch_id,
        hits = hits,
      })
    end
  end

  table.sort(file_entry.branches, function(a, b)
    if a.line == b.line then
      return (a.id or 0) < (b.id or 0)
    end
    return a.line < b.line
  end)
end

--- Parse Cobertura XML format
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

  local content = table.concat(lines, "\n")

  -- Use coverage file directory as base for relative path resolution
  -- Relative paths in coverage files are relative to the coverage file location
  local coverage_dir = vim.fn.fnamemodify(file_path, ":p:h")
  
  -- Project root can be used for context, but coverage file directory is the base
  if not project_root then
    project_root = vim.fn.fnamemodify(file_path, ":p:h:h")
  end

  local xml_sources = extract_xml_sources(content)
  local source_roots = {}
  for _, source in ipairs(xml_sources) do
    local normalized = normalize_path(source)
    if normalized then
      table.insert(source_roots, normalized)
    end
  end

  local module_root = find_go_module_root(project_root, 8)
  if not module_root then
    for _, root in ipairs(source_roots) do
      module_root = find_go_module_root(root, 8)
      if module_root then
        break
      end
    end
  end
  if not module_root then
    module_root = find_go_module_root(coverage_dir, 8)
  end

  local module_name = extract_module_name(module_root or project_root)

  -- Return format: {file_path: {lines: [...], branches: [...]}}
  local coverage_data = {}

  -- Extract file/class nodes
  local class_nodes = collect_class_nodes(content)
  for _, file_node in ipairs(class_nodes) do
    local filename = file_node.filename
    if filename then
      local resolved_path =
        resolve_source_path(filename, coverage_dir, project_root, module_name, module_root, source_roots)

      if resolved_path then
        local file_entry = coverage_data[resolved_path]
        if not file_entry then
          file_entry = {
            lines = {},
            branches = {},
          }
          coverage_data[resolved_path] = file_entry
        end

        local line_hits, line_branches = parse_line_nodes(file_node.inner)
        merge_file_entry(file_entry, line_hits, line_branches)
      end
    end
  end

  return coverage_data
end

return M
