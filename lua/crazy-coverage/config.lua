-- Configuration for coverage plugin
local M = {
  -- Highlight groups
  covered_hl = "CoverageCovered",
  uncovered_hl = "CoverageUncovered",
  partial_hl = "CoveragePartial",

  -- Auto-adapt colors based on current theme (background and foreground)
  -- When enabled, automatically adjusts coverage colors to match your colorscheme
  auto_adapt_colors = true,

  -- Manual color overrides (used when auto_adapt_colors = false)
  -- Set to nil to use auto-adaptation, or provide color values
  colors = {
    covered = nil,     -- e.g., "#00AA00" or { bg = "#00AA00", fg = "#FFFFFF" }
    uncovered = nil,   -- e.g., "#FF0000" or { bg = "#FF0000", fg = "#FFFFFF" }
    partial = nil,     -- e.g., "#FFAA00" or { bg = "#FFAA00", fg = "#FFFFFF" }
  },

  -- Virtual text position: 'eol', 'inline', 'overlay', 'right_align'
  virt_text_pos = "eol",

  -- Show hit count in virtual text by default when overlay is enabled
  show_hit_count = true,
  
  -- Show hit count by default when toggling overlay on
  default_show_hit_count = true,

  -- Show percentage for lines
  show_percentage = false,

  -- Show branch summary per line (taken/total)
  show_branch_summary = true,
  
  -- Enable line highlighting
  enable_line_hl = true,

  -- Auto load coverage when opening file
  auto_load = true,

  -- Coverage file patterns per language
  coverage_patterns = {
    c = { "*.lcov", "coverage.json", "coverage.xml", "*.profdata" },
    cpp = { "*.lcov", "coverage.json", "coverage.xml", "*.profdata" },
  },

  -- Directories to search for coverage files (relative to project root)
  -- Search order: standard directories first, then custom directories
  coverage_dirs = {
    "build/coverage",  -- Standard CMake coverage output
    "coverage",        -- Standard coverage directory
    "build",           -- Build directory root
    ".",               -- Project root
  },

  -- Project root patterns (for finding coverage files)
  project_markers = { ".git", "CMakeLists.txt", "Makefile", "compile_commands.json" },

  -- Cache settings
  cache_enabled = true,
  cache_dir = vim.fn.stdpath("cache") .. "/crazy-coverage.nvim",
}

--- Check if file is a valid coverage file by detecting its format
---@param file_path string
---@return boolean
local function is_coverage_file(file_path)
  if vim.fn.filereadable(file_path) ~= 1 then
    return false
  end
  
  local lines = vim.fn.readfile(file_path, '', 10)
  if not lines or #lines == 0 then
    return false
  end
  
  local content = table.concat(lines, "\n")
  
  -- Format detection patterns (LCOV, LLVM JSON, Cobertura XML)
  local patterns = {
    "^TN:", "^FN:", "^DA:", "end_of_record",  -- LCOV
    '"version".*"data"', '"data".*{',         -- LLVM JSON
    "<coverage", "<package", "<class", "<line", -- Cobertura XML
  }
  
  for _, pattern in ipairs(patterns) do
    if content:match(pattern) then
      return true
    end
  end
  
  -- Extension-based fallback
  local ext = file_path:match("%.([^.]+)$")
  local valid_exts = {
    lcov = true, info = true, json = true, xml = true,
    profdata = true, gcda = true, gcno = true,
  }
  
  return valid_exts[ext] or false
end

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

  -- Collect all coverage patterns
  local patterns = {}
  for _, pattern_list in pairs(M.coverage_patterns) do
    for _, pattern in ipairs(pattern_list) do
      if not vim.tbl_contains(patterns, pattern) then
        table.insert(patterns, pattern)
      end
    end
  end

  -- Search for files with supported extensions
  for _, dir in ipairs(M.coverage_dirs) do
    local search_dir = project_root .. "/" .. dir
    
    if vim.fn.isdirectory(search_dir) == 1 then
      for _, pattern in ipairs(patterns) do
        local files = vim.fn.glob(search_dir .. "/" .. pattern, false, true)
        if files and #files > 0 then
          table.sort(files)
          local file = files[1]
          
          -- Verify file is valid coverage format
          if is_coverage_file(file) then
            return file
          else
            vim.notify(
              string.format("Found '%s' but it's not a valid coverage file", vim.fn.fnamemodify(file, ":t")),
              vim.log.levels.WARN
            )
          end
        end
      end
    end
  end

  -- No coverage file found - notify user
  local searched_dirs = vim.tbl_map(function(d) return project_root .. "/" .. d end, M.coverage_dirs)
  local msg = string.format(
    "Coverage file not found.\n\nSearched directories:\n  %s\n\nSupported patterns: %s\n\nTo customize search directories, add to your config:\n  coverage_dirs = { 'your/custom/dir', ... }",
    table.concat(searched_dirs, "\n  "),
    table.concat(patterns, ", ")
  )
  vim.notify(msg, vim.log.levels.INFO)
  
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

--- Detect theme colors for auto-adaptation
---@return table colors Table with bg and fg from current Normal highlight
local function detect_theme_colors()
  local normal_hl = vim.api.nvim_get_hl(0, { name = "Normal" })
  
  local bg = normal_hl.bg or 0x000000
  local fg = normal_hl.fg or 0xFFFFFF
  
  -- Convert to hex strings
  local bg_hex = string.format("#%06X", bg)
  local fg_hex = string.format("#%06X", fg)
  
  return { bg = bg_hex, fg = fg_hex }
end

--- Calculate luminance of a color
---@param hex string Hex color string like "#RRGGBB"
---@return number Luminance value between 0 and 1
local function get_luminance(hex)
  local r, g, b = hex:match("#(%x%x)(%x%x)(%x%x)")
  if not r then return 0.5 end
  
  r, g, b = tonumber(r, 16) / 255, tonumber(g, 16) / 255, tonumber(b, 16) / 255
  
  -- Convert to linear RGB
  local function to_linear(c)
    return c <= 0.03928 and c / 12.92 or math.pow((c + 0.055) / 1.055, 2.4)
  end
  
  r, g, b = to_linear(r), to_linear(g), to_linear(b)
  
  -- Calculate relative luminance
  return 0.2126 * r + 0.7152 * g + 0.0722 * b
end

--- Adjust color brightness
---@param hex string Hex color string
---@param factor number Brightness factor (< 1 darker, > 1 lighter)
---@return string Adjusted hex color
local function adjust_brightness(hex, factor)
  local r, g, b = hex:match("#(%x%x)(%x%x)(%x%x)")
  if not r then return hex end
  
  r, g, b = tonumber(r, 16), tonumber(g, 16), tonumber(b, 16)
  
  r = math.min(255, math.floor(r * factor))
  g = math.min(255, math.floor(g * factor))
  b = math.min(255, math.floor(b * factor))
  
  return string.format("#%02X%02X%02X", r, g, b)
end

--- Generate adaptive colors based on theme
---@param theme_colors table Table with bg and fg colors
---@return table colors Table with covered, uncovered, and partial colors
local function generate_adaptive_colors(theme_colors)
  local bg_luminance = get_luminance(theme_colors.bg)
  local is_dark_theme = bg_luminance < 0.5
  
  local colors = {}
  
  if is_dark_theme then
    -- Dark theme: use lighter, saturated colors
    colors.covered = { bg = "#003300", fg = "#00FF00" }
    colors.uncovered = { bg = "#330000", fg = "#FF4444" }
    colors.partial = { bg = "#664400", fg = "#FFFF00" }  -- More orange/yellow with bright yellow text
  else
    -- Light theme: use darker, muted colors
    colors.covered = { bg = "#CCFFCC", fg = "#006600" }
    colors.uncovered = { bg = "#FFCCCC", fg = "#CC0000" }
    colors.partial = { bg = "#FFDD99", fg = "#FF8800" }  -- Bright yellow/orange background
  end
  
  return colors
end

--- Setup highlight groups
function M.setup_highlights()
  local colors
  
  if M.auto_adapt_colors then
    -- Auto-detect theme and adapt colors
    local theme_colors = detect_theme_colors()
    colors = generate_adaptive_colors(theme_colors)
    
    -- Allow manual overrides even with auto-adaptation
    if M.colors.covered then
      colors.covered = M.colors.covered
    end
    if M.colors.uncovered then
      colors.uncovered = M.colors.uncovered
    end
    if M.colors.partial then
      colors.partial = M.colors.partial
    end
  else
    -- Use manual colors or fallback to defaults
    colors = {
      covered = M.colors.covered or { bg = "#00AA00", fg = "NONE" },
      uncovered = M.colors.uncovered or { bg = "#FF0000", fg = "NONE" },
      partial = M.colors.partial or { bg = "#FFAA00", fg = "#000000" },
    }
  end
  
  -- Normalize color format (support both string and table formats)
  local function normalize_color(color)
    if type(color) == "string" then
      return { bg = color, fg = "NONE" }
    elseif type(color) == "table" then
      return color
    end
    return { bg = "#00AA00", fg = "NONE" }
  end
  
  local covered_color = normalize_color(colors.covered)
  local uncovered_color = normalize_color(colors.uncovered)
  local partial_color = normalize_color(colors.partial)
  
  -- Define highlights in global namespace (0)
  vim.api.nvim_set_hl(0, M.covered_hl, {
    bg = covered_color.bg,
    fg = covered_color.fg,
    bold = true,
    default = false,
  })

  vim.api.nvim_set_hl(0, M.uncovered_hl, {
    bg = uncovered_color.bg,
    fg = uncovered_color.fg,
    bold = true,
    default = false,
  })

  vim.api.nvim_set_hl(0, M.partial_hl, {
    bg = partial_color.bg,
    fg = partial_color.fg,
    bold = true,
    default = false,
  })
end

-- Re-apply highlights when colorscheme changes so custom groups persist
local _hl_augroup = vim.api.nvim_create_augroup("CrazyCoverageHighlights", { clear = true })
vim.api.nvim_create_autocmd("ColorScheme", {
  group = _hl_augroup,
  pattern = "*",
  callback = function()
    M.setup_highlights()
  end,
})

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
    auto_adapt_colors = true,
    colors = true,
    virt_text_pos = true,
    show_hit_count = true,
    default_show_hit_count = true,
    show_percentage = true,
    show_branch_summary = true,
    enable_line_hl = true,
    auto_load = true,
    coverage_patterns = true,
    coverage_dirs = true,
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

--- Get current config
---@return table
function M.get_config()
  return vim.deepcopy(M)
end

return M
