-- Cobertura XML format parser
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

--- Specialized extractor for <class ...> ... </class> across newlines
---@param content string
---@return table
local function extract_xml_classes(content)
  local nodes = {}
  local pos = 1
  while true do
    local s, e, attrs = content:find("<class%s+([^>]*)>", pos)
    if not s then break end
    local close_s, close_e = content:find("</class>", e + 1)
    local inner = ""
    if close_s then
      inner = content:sub(e + 1, close_s - 1)
      pos = close_e + 1
    else
      pos = e + 1
    end
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
  local pattern = "<" .. tag_name .. "[%s%S]-([^>/]*)/?>"
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

--- Extract attribute from XML tag
---@param attrs string
---@param attr_name string
---@return string|nil
local function get_attr(attrs, attr_name)
  local pattern = attr_name .. '="([^"]*)"'
  local match = attrs:match(pattern)
  return match
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

  -- Return format: {file_path: {lines: [...], branches: [...]}}
  local coverage_data = {}

  -- Extract file/class nodes
  local class_nodes = extract_xml_classes_with_filename(content)
  if #class_nodes == 0 then
    -- Fallback to generic extractor
    local file_nodes = extract_xml_nodes(content, "class")
    for _, file_node in ipairs(file_nodes) do
      local filename = get_attr(file_node.attrs, "filename")
      if filename then
        -- Resolve relative paths to absolute paths
        local file_path = filename
        -- If path is relative, make it absolute relative to coverage file directory
        if file_path:sub(1, 1) ~= "/" then
          file_path = coverage_dir .. "/" .. file_path
        end
        -- Normalize to absolute path (resolve .. and .)
        file_path = normalize_path(file_path)
        
        local file_entry = {
          lines = {},
          branches = {},
        }

        -- Extract line nodes (support both paired and self-closing)
        local line_nodes = extract_xml_nodes(file_node.inner, "line")
        local sc_nodes = extract_xml_self_closing(file_node.inner, "line")
        for _, n in ipairs(sc_nodes) do table.insert(line_nodes, n) end
        for _, line_node in ipairs(line_nodes) do
          local line_num = tonumber(get_attr(line_node.attrs, "number"))
          local hit_count = tonumber(get_attr(line_node.attrs, "hits")) or 0
          if line_num then
            table.insert(file_entry.lines, {
              line = line_num,
              hits = hit_count,
            })
            
            -- Parse branch information if present
            local branch_nodes = extract_xml_nodes(line_node.inner, "branch")
            for branch_idx, branch_node in ipairs(branch_nodes) do
              local branch_number = tonumber(get_attr(branch_node.attrs, "number")) or branch_idx
              local branch_taken = tonumber(get_attr(branch_node.attrs, "taken")) or 0
              table.insert(file_entry.branches, {
                line = line_num,
                id = branch_number,
                hits = branch_taken,
              })
            end
          end
        end

        coverage_data[file_path] = file_entry
      end
    end
  else
    for _, file_node in ipairs(class_nodes) do
      local filename = file_node.filename
      if filename then
      -- Resolve relative paths to absolute paths
      local file_path = filename
      -- If path is relative, make it absolute relative to coverage file directory
      if file_path:sub(1, 1) ~= "/" then
        file_path = coverage_dir .. "/" .. file_path
      end
      -- Normalize to absolute path (resolve .. and .)
      file_path = normalize_path(file_path)
      
      local file_entry = {
        lines = {},
        branches = {},
      }

      -- Extract line nodes (support both paired and self-closing)
      local line_nodes = extract_xml_nodes(file_node.inner, "line")
      local sc_nodes = extract_xml_self_closing(file_node.inner, "line")
      for _, n in ipairs(sc_nodes) do table.insert(line_nodes, n) end
      for _, line_node in ipairs(line_nodes) do
        local line_num = tonumber(get_attr(line_node.attrs, "number"))
        local hit_count = tonumber(get_attr(line_node.attrs, "hits")) or 0
        if line_num then
          table.insert(file_entry.lines, {
            line = line_num,
            hits = hit_count,
          })
          
          -- Parse branch information if present
          local branch_nodes = extract_xml_nodes(line_node.inner, "branch")
          for branch_idx, branch_node in ipairs(branch_nodes) do
            local branch_number = tonumber(get_attr(branch_node.attrs, "number")) or branch_idx
            local branch_taken = tonumber(get_attr(branch_node.attrs, "taken")) or 0
            table.insert(file_entry.branches, {
              line = line_num,
              id = branch_number,
              hits = branch_taken,
            })
          end
        end
      end

      coverage_data[file_path] = file_entry
      end
    end
  end

  return coverage_data
end

return M
