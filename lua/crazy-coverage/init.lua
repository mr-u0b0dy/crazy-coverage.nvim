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
  if M.state.enabled then
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
    vim.notify("Coverage overlay enabled", vim.log.levels.INFO)
  else
    vim.notify("No coverage data loaded. Use :CoverageLoad first", vim.log.levels.WARN)
  end
end

--- Disable coverage overlay
function M.disable()
  state.is_enabled = false
  renderer.clear_all()
  vim.notify("Coverage overlay disabled", vim.log.levels.INFO)
end

--- Clear all coverage data
function M.clear()
  renderer.clear_all()
  state.coverage_data = nil
  state.coverage_file = nil
  state.is_enabled = false
  vim.notify("Coverage cleared", vim.log.levels.INFO)
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
end

return M
