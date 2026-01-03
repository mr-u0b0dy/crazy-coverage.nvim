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
  is_enabled = false,
  is_initialized = false,
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
---@return boolean -- true if successful
function M.load_coverage(file_path)
  if not file_path or file_path == "" then
    vim.notify("Coverage Error: No file path provided", vim.log.levels.ERROR)
    return false
  end

  if not utils.file_exists(file_path) then
    vim.notify("Coverage Error: File not found: " .. file_path, vim.log.levels.ERROR)
    return false
  end

  local coverage_data, err = parser_dispatcher.parse(file_path)

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
  state.is_enabled = true

  local ok, render_err = pcall(renderer.render, coverage_data)
  if not ok then
    vim.notify("Coverage Error: Failed to render: " .. tostring(render_err), vim.log.levels.ERROR)
    return false
  end

  vim.notify(string.format("Coverage loaded: %d file(s) from %s", #coverage_data.files, file_path), vim.log.levels.INFO)

  return true
end

--- Auto-load coverage for current buffer
function M.auto_load()
  if state.is_enabled then
    return
  end

  local coverage_file = config.get_coverage_file()
  if coverage_file then
    M.load_coverage(coverage_file)
  end
end

--- Toggle coverage overlay on/off
function M.toggle()
  if state.is_enabled then
    M.disable()
  else
    M.enable()
  end
end

--- Enable coverage overlay
function M.enable()
  if state.coverage_data then
    state.is_enabled = true
    local ok, err = pcall(renderer.render, state.coverage_data)
    if not ok then
      vim.notify("Failed to render coverage: " .. tostring(err), vim.log.levels.ERROR)
      return
    end
  else
    vim.notify("No coverage data loaded. Use :CoverageLoad first", vim.log.levels.WARN)
  end
end

--- Disable coverage overlay
function M.disable()
  state.is_enabled = false
  renderer.clear_all()
end

--- Clear all coverage data
function M.clear()
  renderer.clear_all()
  state.coverage_data = nil
  state.coverage_file = nil
  state.is_enabled = false
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

  for _, file_entry in ipairs(state.coverage_data.files) do
    local entry_path = vim.fn.fnamemodify(file_entry.path, ":p")
    if entry_path == file_path then
      return file_entry
    end
  end

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

--- Create user commands
function M.create_commands()
  vim.api.nvim_create_user_command("CoverageLoad", function(opts)
    local file = opts.args
    if file == "" then
      file = config.get_coverage_file()
      if not file then
        vim.notify("No coverage file found and no file specified", vim.log.levels.ERROR)
        return
      end
    end
    M.load_coverage(file)
  end, { nargs = "?" })

  vim.api.nvim_create_user_command("CoverageToggle", function()
    M.toggle()
  end, {})

  vim.api.nvim_create_user_command("CoverageEnable", function()
    M.enable()
  end, {})

  vim.api.nvim_create_user_command("CoverageDisable", function()
    M.disable()
  end, {})

  vim.api.nvim_create_user_command("CoverageClear", function()
    M.clear()
  end, {})

  vim.api.nvim_create_user_command("CoverageAutoLoad", function()
    M.auto_load()
  end, {})

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
end

return M
