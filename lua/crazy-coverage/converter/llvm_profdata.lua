-- LLVM Profdata converter: wraps llvm-profdata and llvm-cov to convert .profdata to JSON
-- Requires: llvm-profdata and llvm-cov commands available on system
local M = {}
local utils = require("crazy-coverage.utils")

--- Auto-detect binary file in common build directories
---@param profdata_file string -- Path to .profdata file
---@return string|nil -- Path to binary file or nil if not found
local function find_binary_file(profdata_file)
  local profdata_dir = vim.fn.fnamemodify(profdata_file, ":p:h")
  local project_root = profdata_dir
  
  -- Try to find project root by looking for common markers
  local markers = { ".git", "CMakeLists.txt", "Makefile", "compile_commands.json" }
  for i = 1, 5 do  -- Search up to 5 levels
    for _, marker in ipairs(markers) do
      if utils.file_exists(project_root .. "/" .. marker) then
        goto found_root
      end
    end
    project_root = vim.fn.fnamemodify(project_root, ":h")
  end
  ::found_root::
  
  -- Search patterns for binary files in common locations
  local search_patterns = {
    profdata_dir .. "/*",  -- Same directory as profdata
    profdata_dir .. "/../*",  -- Parent directory
    project_root .. "/build/*",
    project_root .. "/build/*/",
    project_root .. "/cmake-build-*/*",
    project_root .. "/target/debug/*",
    project_root .. "/target/release/*",
  }
  
  for _, pattern in ipairs(search_patterns) do
    local files = vim.fn.glob(pattern, false, true)
    for _, file in ipairs(files) do
      -- Check if file is executable (basic heuristic for binary)
      local stat = vim.loop.fs_stat(file)
      if stat and stat.type == "file" then
        -- Check if file is executable and not a known non-binary extension
        if vim.fn.executable(file) == 1 and 
           not file:match("%.[^/]+$") or
           file:match("%.out$") or file:match("%.[eo]$") then
          return file
        end
      end
    end
  end
  
  return nil
end

--- Convert LLVM profdata to JSON format using llvm-cov
---@param profdata_file string -- Path to .profdata file
---@param binary_file string|nil -- Path to instrumented binary (optional, may be auto-detected)
---@return string|nil -- Path to generated JSON file, or nil on error
function M.convert_profdata_to_json(profdata_file, binary_file)
  if not utils.file_exists(profdata_file) then
    return nil
  end

  local output_file = vim.fn.fnamemodify(profdata_file, ":p:h") .. "/coverage_llvm.json"
  
  -- Check if llvm-cov is available
  if vim.fn.executable("llvm-cov") == 0 then
    vim.notify("llvm-cov command not found. Install LLVM tools.", vim.log.levels.ERROR)
    return nil
  end
  
  -- Get or auto-detect binary file
  if not binary_file or not utils.file_exists(binary_file) then
    -- Try config option first
    local config = require("crazy-coverage.config")
    if config.llvm_binary_file and utils.file_exists(config.llvm_binary_file) then
      binary_file = config.llvm_binary_file
    else
      binary_file = find_binary_file(profdata_file)
    end
  end
  
  if not binary_file or not utils.file_exists(binary_file) then
    vim.notify(
      "Cannot find instrumented binary for profdata. Set config.llvm_binary_file or place binary in build directory.",
      vim.log.levels.ERROR
    )
    return nil
  end
  
  -- Build llvm-cov command
  local cmd = string.format(
    "llvm-cov export -instr-profile=%s -branch-coverage %s > %s 2>&1",
    vim.fn.shellescape(profdata_file),
    vim.fn.shellescape(binary_file),
    vim.fn.shellescape(output_file)
  )

  local result = vim.fn.system(cmd)
  local exit_code = vim.v.shell_error
  
  if exit_code ~= 0 then
    vim.notify(
      string.format("llvm-cov export failed (exit %d): %s", exit_code, result),
      vim.log.levels.ERROR
    )
    return nil
  end
  
  if utils.file_exists(output_file) then
    local content = table.concat(utils.read_file(output_file), "")
    if content:match("^%s*{") then
      -- Validate it's proper JSON
      local json_ok = pcall(vim.json.decode, content)
      if json_ok then
        return output_file
      else
        vim.notify("Generated coverage file is not valid JSON", vim.log.levels.ERROR)
      end
    end
  end

  vim.notify("Failed to generate LLVM coverage JSON", vim.log.levels.ERROR)
  return nil
end

--- Auto-detect and convert LLVM profdata
---@param profdata_file string -- Path to .profdata file
---@return table|nil -- CoverageData model or nil on error
function M.parse(profdata_file)
  local json_path = M.convert_profdata_to_json(profdata_file)
  if not json_path then
    return nil
  end

  -- Parse the generated JSON file
  local json_parser = require("crazy-coverage.parser.llvm_json")
  return json_parser.parse(json_path)
end

return M
