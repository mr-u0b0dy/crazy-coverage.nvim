-- Main coverage plugin module
local M = {}

local parser_dispatcher = require("crazy-coverage.parser")
local renderer = require("crazy-coverage.renderer")
local config = require("crazy-coverage.config")
local utils = require("crazy-coverage.utils")

-- State management
local state = {
  coverage_data = nil,
  coverage_file = nil,
  coverage_file_info = nil,  -- Cached file info from config
  project_root = nil,        -- Cached project root
  is_enabled = false,
  is_initialized = false,
  file_watcher = nil,
  last_modified = nil,
}

--- Get current state (read-only access)
---@return table
function M.get_state()
  return vim.deepcopy(state)
end

--- Initialize the coverage plugin
---@param user_config table|nil
function M.setup(user_config)
  if state.is_initialized then
    vim.notify("Coverage plugin already initialized", vim.log.levels.WARN)
    return
  end

  -- Validate and merge user config
  if user_config then
    if type(user_config) ~= "table" then
      vim.notify("Invalid config: expected table", vim.log.levels.ERROR)
      return
    end
    config.set_config(user_config)
  end

  -- Setup renderer
  local ok, err = pcall(renderer.setup)
  if not ok then
    vim.notify("Failed to setup renderer: " .. tostring(err), vim.log.levels.ERROR)
    return
  end

  -- Create user commands
  M.create_commands()
  
  state.is_initialized = true
end

--- Load coverage from file
---@param file_path string
---@param project_root string|nil -- Project root for parser path resolution
---@return boolean -- true if successful
function M.load_coverage(file_path, project_root)
  if not file_path or file_path == "" then
    vim.notify("Coverage Error: No file path provided", vim.log.levels.ERROR)
    return false
  end

  if not utils.file_exists(file_path) then
    vim.notify("Coverage Error: File not found: " .. file_path, vim.log.levels.ERROR)
    return false
  end

  -- Auto-detect project root if not provided
  if not project_root then
    project_root = config.find_project_root(file_path)
  end

  local coverage_data, err = parser_dispatcher.parse(file_path, project_root)

  if not coverage_data then
    vim.notify("Coverage Error: " .. (err or "Unknown error"), vim.log.levels.ERROR)
    return false
  end

  -- Validate coverage data structure
  if not coverage_data.files or type(coverage_data.files) ~= "table" then
    vim.notify("Coverage Error: Invalid coverage data structure", vim.log.levels.ERROR)
    return false
  end

  state.coverage_data = coverage_data
  state.coverage_file = file_path
  state.project_root = project_root  -- Cache project root
  state.coverage_file_info = {        -- Cache file info
    path = file_path,
    project_root = project_root,
    format = utils.detect_format(file_path),
  }
  state.is_enabled = true

  -- Debug: Log file paths in coverage data
  vim.notify(string.format("Coverage loaded: %d file(s) from %s", #coverage_data.files, file_path), vim.log.levels.INFO)
  if config.debug_notifications then
    for i, file_entry in ipairs(coverage_data.files) do
      vim.notify(string.format("  [%d] %s (%d lines)", i, file_entry.path or "unknown", #(file_entry.lines or {})), vim.log.levels.DEBUG)
    end
  end

  local ok, render_err = pcall(renderer.render, coverage_data, state.project_root)
  if not ok then
    vim.notify("Coverage Error: Failed to render: " .. tostring(render_err), vim.log.levels.ERROR)
    return false
  end

  return true
end

--- Start watching coverage file for changes
local function start_file_watcher()
  if state.file_watcher then
    return -- Already watching
  end
  
  if not state.coverage_file or not utils.file_exists(state.coverage_file) then
    return
  end
  
  -- Check file modification time
  local function check_file_modified()
    local stat = vim.loop.fs_stat(state.coverage_file)
    if stat then
      local current_mtime = stat.mtime.sec
      if state.last_modified and current_mtime > state.last_modified then
        vim.notify("Coverage file updated, reloading...", vim.log.levels.INFO)
        M.load_coverage(state.coverage_file)
      end
      state.last_modified = current_mtime
    end
  end
  
  -- Initial modification time
  local stat = vim.loop.fs_stat(state.coverage_file)
  if stat then
    state.last_modified = stat.mtime.sec
  end
  
  -- Create timer to check every 2 seconds
  state.file_watcher = vim.loop.new_timer()
  state.file_watcher:start(2000, 2000, vim.schedule_wrap(check_file_modified))
end

--- Stop watching coverage file
local function stop_file_watcher()
  if state.file_watcher then
    state.file_watcher:stop()
    state.file_watcher:close()
    state.file_watcher = nil
    state.last_modified = nil
  end
end

--- Toggle coverage overlay (unified function)
function M.toggle()
  if state.is_enabled then
    -- Disable: clear everything and stop watching
    renderer.clear_all()
    stop_file_watcher()
    state.coverage_data = nil
    state.coverage_file = nil
    state.coverage_file_info = nil
    state.project_root = nil
    state.is_enabled = false
    vim.notify("Coverage disabled", vim.log.levels.INFO)
  else
    -- Enable: reuse cached file info or find new coverage file
    local coverage_file, project_root
    
    if state.coverage_file_info then
      -- Reuse previously identified file
      coverage_file = state.coverage_file_info.path
      project_root = state.coverage_file_info.project_root
      vim.notify("Reusing previously loaded coverage file", vim.log.levels.INFO)
    else
      -- Find new coverage file
      coverage_file = config.get_coverage_file()
      if not coverage_file then
        vim.notify("No coverage file found in project", vim.log.levels.WARN)
        return
      end
      project_root = config.find_project_root(coverage_file)
    end
    
    if M.load_coverage(coverage_file, project_root) then
      start_file_watcher()
    end
  end
end

--- Enable coverage overlay (deprecated, use toggle)
function M.enable()
  if not state.is_enabled then
    M.toggle()
  end
end

--- Disable coverage overlay (deprecated, use toggle)
function M.disable()
  if state.is_enabled then
    M.toggle()
  end
end

--- Clear all coverage data (deprecated, use toggle to disable)
function M.clear()
  if state.is_enabled then
    M.toggle()
  end
end

--- Get coverage info for the current buffer
---@return table|nil -- file_entry with coverage data, or nil
local function get_current_file_coverage()
  if not state.coverage_data or not state.coverage_data.files then
    return nil
  end

  local buf = vim.api.nvim_get_current_buf()
  local file_path = vim.api.nvim_buf_get_name(buf)
  
  if file_path == "" then
    return nil
  end

  -- Normalize path for comparison
  file_path = vim.fn.fnamemodify(file_path, ":p")
  
  -- Debug: Log what we're looking for
  vim.notify(string.format("DEBUG: Looking for coverage of: %s", file_path), vim.log.levels.INFO)
  vim.notify(string.format("DEBUG: Coverage data has %d files", #state.coverage_data.files), vim.log.levels.INFO)

  for i, file_entry in ipairs(state.coverage_data.files) do
    local entry_path = vim.fn.fnamemodify(file_entry.path, ":p")
    vim.notify(string.format("DEBUG: [%d] Comparing with: %s", i, entry_path), vim.log.levels.INFO)
    if entry_path == file_path then
      vim.notify(string.format("DEBUG: ✓ Match found! Lines: %d", #(file_entry.lines or {})), vim.log.levels.INFO)
      return file_entry
    end
  end

  vim.notify("DEBUG: ✗ No match found in coverage data", vim.log.levels.WARN)
  return nil
end

--- Navigate to next/previous line matching a coverage filter
---@param direction number -- 1 for next, -1 for previous
---@param filter function -- function(line_info, branches) -> boolean
local function navigate_to_coverage(direction, filter)
  if not state.coverage_data then
    vim.notify("No coverage data loaded. Use :CoverageLoad first", vim.log.levels.WARN)
    return
  end

  local file_entry = get_current_file_coverage()
  if not file_entry then
    vim.notify("No coverage data for current file", vim.log.levels.WARN)
    return
  end

  if not file_entry.lines or #file_entry.lines == 0 then
    vim.notify("No line coverage data for current file", vim.log.levels.WARN)
    return
  end

  -- Build branch map
  local branch_map = {}
  for _, br in ipairs(file_entry.branches or {}) do
    if not branch_map[br.line] then
      branch_map[br.line] = {}
    end
    table.insert(branch_map[br.line], br)
  end

  local current_line = vim.api.nvim_win_get_cursor(0)[1]
  local lines = file_entry.lines
  local found_line = nil

  if direction == 1 then
    -- Search forward
    for _, line_info in ipairs(lines) do
      if line_info.line_num > current_line then
        local branches = branch_map[line_info.line_num]
        if filter(line_info, branches) then
          found_line = line_info.line_num
          break
        end
      end
    end
    -- Wrap around
    if not found_line then
      for _, line_info in ipairs(lines) do
        if line_info.line_num <= current_line then
          local branches = branch_map[line_info.line_num]
          if filter(line_info, branches) then
            found_line = line_info.line_num
            break
          end
        end
      end
    end
  else
    -- Search backward
    for i = #lines, 1, -1 do
      local line_info = lines[i]
      if line_info.line_num < current_line then
        local branches = branch_map[line_info.line_num]
        if filter(line_info, branches) then
          found_line = line_info.line_num
          break
        end
      end
    end
    -- Wrap around
    if not found_line then
      for i = #lines, 1, -1 do
        local line_info = lines[i]
        if line_info.line_num >= current_line then
          local branches = branch_map[line_info.line_num]
          if filter(line_info, branches) then
            found_line = line_info.line_num
            break
          end
        end
      end
    end
  end

  if found_line then
    vim.api.nvim_win_set_cursor(0, { found_line, 0 })
    vim.cmd("normal! zz") -- Center the screen
  end
end

--- Navigate to next covered line
function M.next_covered()
  navigate_to_coverage(1, function(line_info, _)
    return line_info.covered and line_info.hit_count > 0
  end)
end

--- Navigate to previous covered line
function M.prev_covered()
  navigate_to_coverage(-1, function(line_info, _)
    return line_info.covered and line_info.hit_count > 0
  end)
end

--- Navigate to next uncovered line
function M.next_uncovered()
  navigate_to_coverage(1, function(line_info, _)
    return not line_info.covered or line_info.hit_count == 0
  end)
end

--- Navigate to previous uncovered line
function M.prev_uncovered()
  navigate_to_coverage(-1, function(line_info, _)
    return not line_info.covered or line_info.hit_count == 0
  end)
end

--- Navigate to next partially covered line (has branches with mixed coverage)
function M.next_partial()
  navigate_to_coverage(1, function(line_info, branches)
    if not branches or #branches == 0 then
      return false
    end
    local taken = 0
    local total = #branches
    for _, br in ipairs(branches) do
      if (br.hit_count or 0) > 0 then
        taken = taken + 1
      end
    end
    return taken > 0 and taken < total
  end)
end

--- Navigate to previous partially covered line (has branches with mixed coverage)
function M.prev_partial()
  navigate_to_coverage(-1, function(line_info, branches)
    if not branches or #branches == 0 then
      return false
    end
    local taken = 0
    local total = #branches
    for _, br in ipairs(branches) do
      if (br.hit_count or 0) > 0 then
        taken = taken + 1
      end
    end
    return taken > 0 and taken < total
  end)
end

--- Toggle hit count display
function M.toggle_hitcount()
  local current_config = config.get_config()
  current_config.show_hit_count = not current_config.show_hit_count
  config.set_config(current_config)
  
  -- Re-render if coverage is enabled
  if state.is_enabled and state.coverage_data then
    renderer.render(state.coverage_data)
  end
  
  local status = current_config.show_hit_count and "enabled" or "disabled"
  vim.notify("Hit count display " .. status, vim.log.levels.INFO)
end

--- Create user commands
function M.create_commands()
  vim.api.nvim_create_user_command("CoverageToggle", function()
    M.toggle()
  end, {})

  vim.api.nvim_create_user_command("CoverageToggleHitCount", function()
    M.toggle_hitcount()
  end, {})
  
  -- Load coverage from specific file
  vim.api.nvim_create_user_command("CoverageLoad", function(opts)
    local file = opts.args
    if file == "" then
      file = config.get_coverage_file()
      if not file then
        vim.notify("No coverage file found and no file specified", vim.log.levels.ERROR)
        return
      end
    end
    local project_root = config.find_project_root(file)
    M.load_coverage(file, project_root)
    if state.is_enabled then
      start_file_watcher()
    end
  end, { nargs = "?" })

  -- Navigation commands
  vim.api.nvim_create_user_command("CoverageNextCovered", function()
    M.next_covered()
  end, {})

  vim.api.nvim_create_user_command("CoveragePrevCovered", function()
    M.prev_covered()
  end, {})

  vim.api.nvim_create_user_command("CoverageNextUncovered", function()
    M.next_uncovered()
  end, {})

  vim.api.nvim_create_user_command("CoveragePrevUncovered", function()
    M.prev_uncovered()
  end, {})

  vim.api.nvim_create_user_command("CoverageNextPartial", function()
    M.next_partial()
  end, {})

  vim.api.nvim_create_user_command("CoveragePrevPartial", function()
    M.prev_partial()
  end, {})
  
  vim.api.nvim_create_user_command("CoverageToggleHitCount", function()
    M.toggle_hitcount()
  end, {})
end

return M
