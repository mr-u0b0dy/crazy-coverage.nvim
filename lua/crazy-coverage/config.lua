-- Configuration for coverage plugin
local M = {
  -- Highlight groups
  covered_hl = "CoverageCovered",
  uncovered_hl = "CoverageUncovered",
  partial_hl = "CoveragePartial",

  -- Virtual text position: 'eol', 'inline', 'overlay', 'right_align'
  virt_text_pos = "eol",

  -- Show hit count in virtual text
  show_hit_count = true,

  -- Show percentage for lines
  show_percentage = false,

  -- Show branch summary per line (taken/total)
  show_branch_summary = false,

  -- Auto load coverage when opening file
  auto_load = true,

  -- Coverage file patterns per language
  coverage_patterns = {
    c = { "*.lcov", "coverage.json", "coverage.xml", "*.profdata" },
    cpp = { "*.lcov", "coverage.json", "coverage.xml", "*.profdata" },
  },

  -- Project root patterns (for finding coverage files)
  project_markers = { ".git", "CMakeLists.txt", "Makefile", "compile_commands.json" },

  -- Cache settings
  cache_enabled = true,
  cache_dir = vim.fn.stdpath("cache") .. "/crazy-coverage.nvim",
}

--- Get coverage file for current buffer
---@param buf number|nil
---@return string|nil
function M.get_coverage_file(buf)
  buf = buf or vim.api.nvim_get_current_buf()
  local buf_path = vim.api.nvim_buf_get_name(buf)
  if buf_path == "" then
    return nil
  end

  local project_root = M.find_project_root(buf_path)
  if not project_root then
    return nil
  end

  -- Look for coverage files in project root
  local coverage_files = {
    project_root .. "/coverage.lcov",
    project_root .. "/coverage.json",
    project_root .. "/coverage.xml",
    project_root .. "/coverage.profdata",
  }

  for _, file in ipairs(coverage_files) do
    if vim.fn.filereadable(file) == 1 then
      return file
    end
  end

  return nil
end

--- Find project root directory
---@param start_path string
---@return string|nil
function M.find_project_root(start_path)
  if not start_path or start_path == "" then
    return nil
  end
  
  local path = vim.fn.fnamemodify(start_path, ":p:h")

  for _ = 1, 10 do
    for _, marker in ipairs(M.project_markers) do
      local marker_path = path .. "/" .. marker
      if vim.fn.isdirectory(marker_path) == 1 or vim.fn.filereadable(marker_path) == 1 then
        return path
      end
    end
    local parent = vim.fn.fnamemodify(path, ":p:h:h")
    if parent == path or parent == "" then
      break
    end
    path = parent
  end

  return nil
end

--- Setup highlight groups
function M.setup_highlights()
  local ns_id = vim.api.nvim_create_namespace("coverage")

  vim.api.nvim_set_hl(ns_id, M.covered_hl, {
    fg = "#00ff00",
    bg = nil,
    bold = false,
  })

  vim.api.nvim_set_hl(ns_id, M.uncovered_hl, {
    fg = "#ff0000",
    bg = nil,
    bold = false,
  })

  vim.api.nvim_set_hl(ns_id, M.partial_hl, {
    fg = "#ffaa00",
    bg = nil,
    bold = false,
  })
end

--- Merge user config
---@param user_config table
function M.set_config(user_config)
  if not user_config or type(user_config) ~= "table" then
    return
  end
  
  -- Whitelist of valid config keys
  local valid_keys = {
    covered_hl = true,
    uncovered_hl = true,
    partial_hl = true,
    virt_text_pos = true,
    show_hit_count = true,
    show_percentage = true,
    show_branch_summary = true,
    auto_load = true,
    coverage_patterns = true,
    project_markers = true,
    cache_enabled = true,
    cache_dir = true,
  }
  
  for key, value in pairs(user_config) do
    if valid_keys[key] then
      M[key] = value
    else
      vim.notify("Unknown config key: " .. tostring(key), vim.log.levels.WARN)
    end
  end
end

return M
