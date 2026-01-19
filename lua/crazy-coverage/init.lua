-- Main coverage plugin module
local M = {}

local parser_dispatcher = require("crazy-coverage.parser")
local renderer = require("crazy-coverage.renderer")
local config = require("crazy-coverage.config")
local utils = require("crazy-coverage.utils")
local notify_once = vim.notify_once or vim.notify

-- Centralized notification helper that gates debug logs and dedupes INFO popups
local function notify(msg, level)
  level = level or vim.log.levels.INFO
  -- Always check current config state, not cached value
  if level == vim.log.levels.DEBUG then
    if not (config.debug_notifications or config.dev) then
      return
    end
  end

  if level == vim.log.levels.INFO then
    notify_once(msg, level)
    return
  end

  vim.notify(msg, level)
end

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
  last_size = nil,           -- Track file size for change detection
  coverage_file_missing_notified = false, -- Prevent duplicate deletion warnings
  last_enabled_display = "sign", -- Track the last enabled display mode for toggle
}

local autocmd_group = vim.api.nvim_create_augroup("CrazyCoverageAutoRender", { clear = true })

-- Forward declarations (used before definition)
local start_file_watcher
local stop_file_watcher
local setup_autocmds

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

  -- Auto-render coverage when switching/opening buffers
  setup_autocmds()
  
  state.is_initialized = true
end

--- Load coverage from file
---@param file_path string
---@param project_root string|nil -- Project root for parser path resolution
---@return boolean -- true if successful
function M.load_coverage(file_path, project_root)
  if not file_path or file_path == "" then
    notify("Coverage Error: No file path provided", vim.log.levels.ERROR)
    return false
  end

  if not utils.file_exists(file_path) then
    notify("Coverage Error: File not found: " .. file_path, vim.log.levels.ERROR)
    return false
  end

  -- Auto-detect project root if not provided
  if not project_root then
    project_root = config.find_project_root(file_path)
  end

  local coverage_data, err = parser_dispatcher.parse(file_path, project_root)

  if not coverage_data then
    notify("Coverage Error: " .. (err or "Unknown error"), vim.log.levels.ERROR)
    return false
  end

  -- Validate coverage data structure (should be {file_path: {lines: [...], branches: [...]}})
  if type(coverage_data) ~= "table" then
    notify("Coverage Error: Invalid coverage data structure", vim.log.levels.ERROR)
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
  state.coverage_file_missing_notified = false

  -- Debug: Log file paths in coverage data
  local file_count = 0
  for _ in pairs(coverage_data) do
    file_count = file_count + 1
  end
  notify(string.format("Coverage loaded: %d file(s) from %s", file_count, file_path), vim.log.levels.INFO)
  if config.debug_notifications then
    for file_path, file_entry in pairs(coverage_data) do
      notify(string.format("  %s (%d lines)", file_path, #(file_entry.lines or {})), vim.log.levels.DEBUG)
    end
  end

  local ok, render_err = pcall(renderer.render, coverage_data, state.project_root)
  if not ok then
    notify("Coverage Error: Failed to render: " .. tostring(render_err), vim.log.levels.ERROR)
    return false
  end

  return true
end

--- Start watching coverage file for changes
start_file_watcher = function()
  if state.file_watcher then
    return -- Already watching
  end
  
  if not state.coverage_file or not utils.file_exists(state.coverage_file) then
    return
  end
  
  -- Get initial file stats
  local stat = vim.loop.fs_stat(state.coverage_file)
  if stat then
    state.last_modified = stat.mtime.sec * 1e9 + stat.mtime.nsec  -- Use nanosecond precision
    state.last_size = stat.size
  end
  
  local config = require("crazy-coverage.config")
  local debounce_timer = nil
  local pending_reload = false
  
  -- Handle file change events
  local function on_change(err, filename, events)
    if err then
      vim.schedule(function()
        notify("File watch error: " .. err, vim.log.levels.WARN)
        stop_file_watcher()
      end)
      return
    end
    
    -- File was deleted or renamed
    if events and events.rename then
      vim.schedule(function()
        if not utils.file_exists(state.coverage_file) then
          if not state.coverage_file_missing_notified then
            state.coverage_file_missing_notified = true
            notify("Coverage file was deleted or moved", vim.log.levels.WARN)
          end
          stop_file_watcher()
          return
        end
      end)
      return
    end
    
    -- Debounce rapid changes (file being written)
    if debounce_timer then
      debounce_timer:stop()
    end
    
    if not debounce_timer then
      debounce_timer = vim.loop.new_timer()
    end
    
    pending_reload = true
    
    -- Wait for file to stabilize before reloading
    local debounce_ms = config.watch_debounce_ms or 200
    debounce_timer:start(debounce_ms, 0, vim.schedule_wrap(function()
      if not pending_reload then
        return
      end
      pending_reload = false
      
      -- Check if file actually changed (mtime + size)
      local new_stat = vim.loop.fs_stat(state.coverage_file)
      if not new_stat then
        if not state.coverage_file_missing_notified then
          state.coverage_file_missing_notified = true
          notify("Coverage file no longer exists", vim.log.levels.WARN)
        end
        stop_file_watcher()
        return
      end
      
      local new_mtime = new_stat.mtime.sec * 1e9 + new_stat.mtime.nsec
      local new_size = new_stat.size
      
      -- Only reload if file actually changed
      if new_mtime > state.last_modified or new_size ~= state.last_size then
        notify("Coverage file updated, reloading...", vim.log.levels.INFO)
        
        -- Clear old coverage data before reload to avoid confusion
        local old_data = state.coverage_data
        state.coverage_data = nil
        
        -- Pass cached project_root to maintain path resolution consistency
        if M.load_coverage(state.coverage_file, state.project_root) then
          state.last_modified = new_mtime
          state.last_size = new_size
        else
          notify("Coverage reload failed, keeping old data", vim.log.levels.ERROR)
          -- Restore old data on failure
          state.coverage_data = old_data
        end
      end
    end))
  end
  
  -- Create fs_event watcher for the file
  state.file_watcher = vim.loop.new_fs_event()
  local watch_flags = { recursive = false }
  
  -- Watch the file directly
  local ok, watch_err = pcall(function()
    state.file_watcher:start(state.coverage_file, watch_flags, on_change)
  end)
  
  if not ok then
    notify("Failed to start file watcher: " .. tostring(watch_err), vim.log.levels.WARN)
    state.file_watcher = nil
  end
end

--- Stop watching coverage file
stop_file_watcher = function()
  if state.file_watcher then
    -- Use pcall in case watcher is already closed
    pcall(function()
      state.file_watcher:stop()
    end)
    pcall(function()
      state.file_watcher:close()
    end)
    state.file_watcher = nil
    state.last_modified = nil
    state.last_size = nil
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
---@param buf number|nil -- buffer handle (defaults to current buffer)
---@return table|nil -- file_entry with coverage data, or nil
local function get_buffer_coverage(buf)
  if not state.coverage_data or type(state.coverage_data) ~= "table" then
    return nil
  end

  buf = buf or vim.api.nvim_get_current_buf()
  if not buf or not vim.api.nvim_buf_is_valid(buf) then
    return nil
  end

  local file_path = vim.api.nvim_buf_get_name(buf)
  if file_path == "" then
    return nil
  end

  -- Normalize path for comparison
  file_path = vim.fn.fnamemodify(file_path, ":p")
  
  -- Debug: Log what we're looking for
  notify(string.format("DEBUG: Looking for coverage of: %s", file_path), vim.log.levels.DEBUG)
  local file_count = 0
  for _ in pairs(state.coverage_data) do
    file_count = file_count + 1
  end
  notify(string.format("DEBUG: Coverage data has %d files", file_count), vim.log.levels.DEBUG)

  for entry_path, file_entry in pairs(state.coverage_data) do
    local normalized_entry_path = vim.fn.fnamemodify(entry_path, ":p")
    notify(string.format("DEBUG: Comparing with: %s", normalized_entry_path), vim.log.levels.DEBUG)
    if normalized_entry_path == file_path then
      notify(string.format("DEBUG: ✓ Match found! Lines: %d", #(file_entry.lines or {})), vim.log.levels.DEBUG)
      return file_entry
    end
  end

  notify("DEBUG: ✗ No match found in coverage data", vim.log.levels.DEBUG)
  return nil
end

--- Render coverage in a specific buffer if data is available
---@param buf number|nil
local function render_buffer_coverage(buf)
  if not state.is_enabled or not state.coverage_data then
    return
  end

  buf = buf or vim.api.nvim_get_current_buf()
  if not buf or not vim.api.nvim_buf_is_valid(buf) then
    return
  end

  local file_entry = get_buffer_coverage(buf)
  if not file_entry then
    return
  end

  local ok, err = pcall(renderer.render_file, buf, file_entry)
  if not ok then
    notify("Coverage render failed: " .. tostring(err), vim.log.levels.WARN)
  end
end

setup_autocmds = function()
  vim.api.nvim_create_autocmd({ "BufEnter", "BufWinEnter" }, {
    group = autocmd_group,
    callback = function(args)
      if not state.is_enabled or not state.coverage_data then
        return
      end

      local buf = args.buf
      if not buf or not vim.api.nvim_buf_is_loaded(buf) then
        return
      end

      local name = vim.api.nvim_buf_get_name(buf)
      if name == "" then
        return
      end

      render_buffer_coverage(buf)
    end,
  })
end

--- Navigate to next/previous line matching a coverage filter
---@param direction number -- 1 for next, -1 for previous
---@param filter function -- function(line_info, branches) -> boolean
local function navigate_to_coverage(direction, filter)
  if not state.coverage_data then
    notify("No coverage data loaded. Use :CoverageLoad first", vim.log.levels.WARN)
    return
  end

  local file_entry = get_buffer_coverage()
  if not file_entry then
    notify("No coverage data for current file", vim.log.levels.WARN)
    return
  end

  if not file_entry.lines or #file_entry.lines == 0 then
    notify("No line coverage data for current file", vim.log.levels.WARN)
    return
  end

  -- Normalize line info to a consistent shape so we can accept multiple parser outputs
  local normalized_lines = {}
  for _, line_info in ipairs(file_entry.lines or {}) do
    local line_num = line_info.line_num or line_info.line
    if type(line_num) == "number" then
      local hit_count = line_info.hit_count
      if hit_count == nil then
        hit_count = line_info.hits
      end
      hit_count = hit_count or 0

      local covered = line_info.covered
      if covered == nil then
        covered = hit_count > 0
      end

      table.insert(normalized_lines, {
        line_num = line_num,
        hit_count = hit_count,
        covered = covered,
      })
    end
  end

  if #normalized_lines == 0 then
    notify("No line coverage data for current file", vim.log.levels.WARN)
    return
  end

  table.sort(normalized_lines, function(a, b)
    return a.line_num < b.line_num
  end)

  -- Build branch map with normalized entries
  local branch_map = {}
  for _, br in ipairs(file_entry.branches or {}) do
    local line_num = br.line_num or br.line
    if type(line_num) == "number" then
      local hit_count = br.hit_count
      if hit_count == nil then
        hit_count = br.hits
      end
      hit_count = hit_count or 0

      local covered = br.covered
      if covered == nil then
        covered = hit_count > 0
      end

      if not branch_map[line_num] then
        branch_map[line_num] = {}
      end

      table.insert(branch_map[line_num], vim.tbl_extend("force", br, {
        line_num = line_num,
        hit_count = hit_count,
        covered = covered,
      }))
    end
  end

  local current_line = vim.api.nvim_win_get_cursor(0)[1]
  local lines = normalized_lines
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
    if config.center_on_navigate then
      vim.cmd("normal! zz") -- Center the screen
    end
  end
end

--- Navigate to next covered line
function M.next_covered()
  local count = vim.v.count1
  for _ = 1, count do
    navigate_to_coverage(1, function(line_info, branches)
      -- Covered means: executed AND all branches taken (or no branches)
      if line_info.hit_count == 0 then
        return false  -- Not executed
      end
      
      -- If branches exist, all must be taken
      if branches and #branches > 0 then
        local taken = 0
        for _, br in ipairs(branches) do
          if (br.hit_count or 0) > 0 then
            taken = taken + 1
          end
        end
        return taken == #branches  -- All branches must be taken
      end
      
      return true  -- Executed with no branches = covered
    end)
  end
end

--- Navigate to previous covered line
function M.prev_covered()
  local count = vim.v.count1
  for _ = 1, count do
    navigate_to_coverage(-1, function(line_info, branches)
      -- Covered means: executed AND all branches taken (or no branches)
      if line_info.hit_count == 0 then
        return false  -- Not executed
      end
      
      -- If branches exist, all must be taken
      if branches and #branches > 0 then
        local taken = 0
        for _, br in ipairs(branches) do
          if (br.hit_count or 0) > 0 then
            taken = taken + 1
          end
        end
        return taken == #branches  -- All branches must be taken
      end
      
      return true  -- Executed with no branches = covered
    end)
  end
end

--- Navigate to next uncovered line
function M.next_uncovered()
  local count = vim.v.count1
  for _ = 1, count do
    navigate_to_coverage(1, function(line_info, _)
      return line_info.hit_count == 0
    end)
  end
end

--- Navigate to previous uncovered line
function M.prev_uncovered()
  local count = vim.v.count1
  for _ = 1, count do
    navigate_to_coverage(-1, function(line_info, _)
      return line_info.hit_count == 0
    end)
  end
end

--- Navigate to next partially covered line (has branches with mixed coverage)
function M.next_partial()
  local count = vim.v.count1
  for _ = 1, count do
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
end

--- Navigate to previous partially covered line (has branches with mixed coverage)
function M.prev_partial()
  local count = vim.v.count1
  for _ = 1, count do
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
end

--- Toggle hit count display
--- Toggle hit count display (enable/disable)
function M.toggle_hitcount()
  local current_config = config.get_config()
  local current_display = current_config.hit_count.display
  
  if current_display == "" then
    -- Enable: restore the last enabled display mode
    current_config.hit_count.display = state.last_enabled_display
  else
    -- Disable: save the current display mode and set to empty
    state.last_enabled_display = current_display
    current_config.hit_count.display = ""
  end
  
  config.set_config(current_config)
  
  -- Re-render if coverage is enabled
  if state.is_enabled and state.coverage_data then
    renderer.render(state.coverage_data, state.project_root)
  end
  
  local status = current_config.hit_count.display ~= "" and "enabled (" .. current_config.hit_count.display .. ")" or "disabled"
  vim.notify("Hit count display: " .. status, vim.log.levels.INFO)
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
