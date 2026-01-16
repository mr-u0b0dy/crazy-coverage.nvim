-- Renderer module - handles extmark rendering of coverage data
local M = {}
local config = require("crazy-coverage.config")
local utils = require("crazy-coverage.utils")

--- Calculate branch coverage statistics for a line
-- @param branches table Array of branch data for a line
-- @return number, number Total branches and taken branches
local function calculate_branch_stats(branches)
  if not branches or #branches == 0 then
    return 0, 0
  end
  local total = #branches
  local taken = 0
  for _, br in ipairs(branches) do
    if (br.hit_count or 0) > 0 then
      taken = taken + 1
    end
  end
  return total, taken
end

--- Determine highlight group based on coverage state
-- @param line_info table Line coverage information
-- @param branches table Array of branch data for the line
-- @param branch_total number Total branches on line
-- @param branch_taken number Taken branches on line
-- @return string Highlight group name
local function get_highlight_group(line_info, branches, branch_total, branch_taken)
  -- Check for partial branch coverage first
  if branches and branch_total > 0 then
    if branch_taken > 0 and branch_taken < branch_total then
      return config.partial_hl  -- Partial coverage
    elseif branch_taken == 0 then
      return config.uncovered_hl  -- No branches taken
    elseif branch_taken == branch_total then
      return config.covered_hl  -- All branches taken
    end
  end
  
  -- Fall back to line coverage
  return line_info.covered and config.covered_hl or config.uncovered_hl
end

M.namespace = vim.api.nvim_create_namespace("coverage_plugin")

--- Clear all coverage marks from a buffer
---@param buf number|nil
function M.clear_buffer(buf)
  buf = buf or vim.api.nvim_get_current_buf()
  if not vim.api.nvim_buf_is_valid(buf) then
    return
  end
  vim.api.nvim_buf_clear_namespace(buf, M.namespace, 0, -1)
end

--- Clear all coverage marks from all buffers
function M.clear_all()
  for _, buf in ipairs(vim.api.nvim_list_bufs()) do
    if vim.api.nvim_buf_is_valid(buf) then
      M.clear_buffer(buf)
    end
  end
end

--- Render coverage data to buffers
---@param coverage_data table -- CoverageData model
---@param project_root string|nil -- Project root for context (from cache)
function M.render(coverage_data, project_root)
  if not coverage_data then
    error("coverage_data is required")
  end
  
  if not coverage_data.files or type(coverage_data.files) ~= "table" then
    error("coverage_data.files must be a table")
  end

  if project_root and config.debug_notifications then
    vim.notify(string.format("RENDER: Using project root: %s", project_root), vim.log.levels.DEBUG)
  end

  local rendered_count = 0
  if config.debug_notifications then
    vim.notify(string.format("RENDER: Starting render for %d files", #coverage_data.files), vim.log.levels.DEBUG)
  end
  
  for _, file_entry in ipairs(coverage_data.files) do
    if file_entry and file_entry.path then
      if config.debug_notifications then
        vim.notify(string.format("RENDER: File entry path: %s (lines: %d)", file_entry.path, #(file_entry.lines or {})), vim.log.levels.DEBUG)
      end
      local buf = utils.get_buffer_by_path(file_entry.path)
      if buf then
        if config.debug_notifications then
          vim.notify(string.format("RENDER: Found buffer %d, rendering %d lines", buf, #(file_entry.lines or {})), vim.log.levels.DEBUG)
        end
        local ok, err = pcall(M.render_file, buf, file_entry)
        if ok then
          rendered_count = rendered_count + 1
        else
          vim.notify("Failed to render " .. file_entry.path .. ": " .. tostring(err), vim.log.levels.WARN)
        end
      elseif config.debug_notifications then
        vim.notify(string.format("RENDER: No buffer found for %s", file_entry.path), vim.log.levels.DEBUG)
      end
    end
  end
  
  return rendered_count
end

--- Render coverage for a specific file
---@param buf number
---@param file_entry table
function M.render_file(buf, file_entry)
  if not buf or not vim.api.nvim_buf_is_valid(buf) then
    error("Invalid buffer")
  end
  
  if not file_entry or type(file_entry) ~= "table" then
    error("file_entry must be a table")
  end
  
  -- Require at least line data or branch data
  if (not file_entry.lines or type(file_entry.lines) ~= "table" or #file_entry.lines == 0) and
     (not file_entry.branches or type(file_entry.branches) ~= "table" or #file_entry.branches == 0) then
    vim.notify("No line or branch data for " .. (file_entry.path or "unknown"), vim.log.levels.WARN)
    return -- No data at all, skip silently
  end

  -- Clear previous marks for this buffer
  M.clear_buffer(buf)
  
  -- Track partial coverage statistics
  local partial_lines = {}

  -- Create a map of line coverage for fast lookup
  local line_map = {}
  for _, line_info in ipairs(file_entry.lines or {}) do
    line_map[line_info.line_num] = line_info
  end

  -- Create a map of branch coverage per line
  local branch_map = {}
  for _, br in ipairs(file_entry.branches or {}) do
    local arr = branch_map[br.line]
    if not arr then
      arr = {}
      branch_map[br.line] = arr
    end
    table.insert(arr, br)
  end

  -- Collect all lines to render (from both line data and branch data)
  local lines_to_render = {}
  local rendered_lines = {}
  
  -- Add lines from line coverage data
  for _, line_info in ipairs(file_entry.lines or {}) do
    table.insert(lines_to_render, line_info)
    rendered_lines[line_info.line_num] = true
  end
  
  -- Add lines from branch coverage that don't have line data
  for line_num, _ in pairs(branch_map) do
    if not rendered_lines[line_num] then
      -- Create synthetic line entry for branch-only coverage
      local branches = branch_map[line_num]
      local total, taken = calculate_branch_stats(branches)
      
      table.insert(lines_to_render, {
        line_num = line_num,
        hit_count = nil,  -- No line hit count, only branch info
        covered = taken == total and taken > 0,  -- Only marked as covered if ALL branches are taken
      })
    end
  end

  -- Render each line
  for _, line_info in ipairs(lines_to_render) do
    local line_num = line_info.line_num
    local hit_count = line_info.hit_count
    local branches = branch_map[line_num]
    
    -- Calculate branch statistics
    local branch_total, branch_taken = calculate_branch_stats(branches)
    
    -- Determine highlight group
    local hl_group = get_highlight_group(line_info, branches, branch_total, branch_taken)
    
    -- Track partial coverage for summary
    if branches and branch_total > 0 and branch_taken > 0 and branch_taken < branch_total then
      table.insert(partial_lines, { line = line_num, taken = branch_taken, total = branch_total })
      if config.debug_notifications then
        vim.notify(
          string.format("PARTIAL: Line %d in %s has partial branch coverage (%d/%d branches taken)", 
            line_num, file_entry.path or "unknown", branch_taken, branch_total),
          vim.log.levels.DEBUG
        )
      end
    end

    -- Build virtual text
    local virt_text = {}
    if config.show_hit_count and hit_count then
      table.insert(virt_text, { " " .. hit_count, hl_group })
    end

    if config.show_percentage and hit_count and hit_count > 0 then
      table.insert(virt_text, { " (hit)", hl_group })
    end

    -- Optional branch summary: b:taken/total
    if config.show_branch_summary and branches and branch_total > 0 then
      table.insert(virt_text, { " b:" .. branch_taken .. "/" .. branch_total, hl_group })
    end

    -- If no virtual text but we have branch data, show a summary anyway
    if #virt_text == 0 and branches and branch_total > 0 then
      table.insert(virt_text, { " b:" .. branch_taken .. "/" .. branch_total, hl_group })
    end

    -- Place extmark on line with both virtual text and line highlighting
    if #virt_text > 0 then
      local extmark_opts = {
        virt_text = virt_text,
        virt_text_pos = config.virt_text_pos,
        priority = 200,
        hl_eol = false,
        strict = false,
      }
      
      -- Add line highlighting if enabled
      if config.enable_line_hl then
        extmark_opts.line_hl_group = hl_group
      end
      
      local ok, err = pcall(vim.api.nvim_buf_set_extmark, buf, M.namespace, line_num - 1, 0, extmark_opts)
      if not ok then
        vim.notify("Failed to set extmark on line " .. line_num .. ": " .. tostring(err), vim.log.levels.ERROR)
      end
    elseif config.enable_line_hl then
      -- If no virtual text but line highlighting is enabled
      local ok2, err2 = pcall(vim.api.nvim_buf_set_extmark, buf, M.namespace, line_num - 1, 0, {
        line_hl_group = hl_group,
        priority = 200,
        strict = false,
      })
      if not ok2 then
        vim.notify("Failed to set extmark (line_hl) on line " .. line_num .. ": " .. tostring(err2), vim.log.levels.ERROR)
      end
    end
  end
  
  -- Report partial coverage summary
  if #partial_lines > 0 then
    local lines_str = {}
    for _, info in ipairs(partial_lines) do
      table.insert(lines_str, string.format("%d(%d/%d)", info.line, info.taken, info.total))
    end
    vim.notify(string.format("PARTIAL COVERAGE: %s has %d lines with partial branch coverage: %s", 
      file_entry.path or "unknown", #partial_lines, table.concat(lines_str, ", ")), vim.log.levels.INFO)
  end
end

--- Set up highlight groups
function M.setup()
  config.setup_highlights()
end

return M
