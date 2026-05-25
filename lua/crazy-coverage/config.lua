-- Configuration for coverage plugin
local utils = require("crazy-coverage.utils")
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

  -- Hit count display configuration
  hit_count = {
    -- Display mode: 'eol', 'inline', 'overlay', 'right_align', or 'sign'
    -- 'sign' displays hit count in the sign column (left gutter)
    -- Other values display as virtual text at the specified position
    display = "eol",

    -- Show hit count by default when toggling overlay on
    show_by_default = true,

    -- Format function for sign text (hit count display in sign column)
    -- Only used when display = 'sign'
    -- Takes hit_count (number) and returns string
    -- Default: shows exact hit count without abbreviation
    sign_text_format = function(hit_count)
      return tostring(hit_count)
    end,
  },

  -- Show percentage for lines
  show_percentage = false,

  -- Show coverage status in the sign column instead of in-buffer line highlighting
  show_coverage_in_sign_column = false,

  -- Show branch summary in branch overlay header (taken/total and percentage)
  show_branch_summary = true,

  -- Enable line highlighting
  enable_line_hl = true,

  -- Center screen when navigating to coverage lines
  center_on_navigate = false,

  -- Auto load coverage when opening file
  auto_load = true,

  -- Show debug notifications
  debug_notifications = false,

  -- LLVM profdata: path to instrumented binary (if not auto-detected)
  -- Example: "build/my_test" or "cmake-build-debug/my_app"
  llvm_binary_file = nil,

  -- File watch debounce in milliseconds (wait after file change before reloading)
  -- Prevents multiple reloads when file is being written
  watch_debounce_ms = 200,

  -- Coverage file patterns per language
  coverage_patterns = {
    c = { "*.lcov", "*.info", "coverage.json", "coverage.xml", "*.profdata" },
    cpp = { "*.lcov", "*.info", "coverage.json", "coverage.xml", "*.profdata" },
    rust = { "*.lcov", "*.info", "coverage.json", "coverage.xml", "coverage-tarpaulin.lcov", "coverage-tarpaulin.json", "coverage-tarpaulin.xml" },
    go = { "coverage.out", "*.lcov", "*.info", "coverage.json", "coverage.xml" },
  },

  -- Directories to search for coverage files (relative to project root)
  -- Search order: standard directories first, then custom directories
  coverage_dirs = {
    "target/tarpaulin", -- Rust tarpaulin default output
    "target/coverage",  -- Rust/other tooling coverage output
    "build/coverage",  -- Standard CMake coverage output
    "coverage",        -- Standard coverage directory
    "build",           -- Build directory root
    ".",               -- Project root
  },

  -- Project root patterns (for finding coverage files)
  project_markers = { ".git", "CMakeLists.txt", "Makefile", "compile_commands.json", "go.mod", "Cargo.toml" },

  -- Cache settings
  cache_enabled = true,
  cache_dir = vim.fn.stdpath("cache") .. "/crazy-coverage.nvim",

  -- Development convenience flag: when true, enables debug notifications
  dev = false,

  -- Branch overlay configuration (floating window)
  branch_overlay = {
    enabled_by_default = false,
    border = "rounded",
    max_height = 12,
    zindex = 45,
    show_ids = true,
    title = "Branch Coverage",
  },

  -- Region overlay configuration (floating window + region highlight)
  region_overlay = {
    enabled_by_default = false,
    border = "rounded",
    max_height = 8,
    zindex = 46,
    title = "Region Coverage",
    highlight_hl = "CoverageRegionActive",
  },

  -- Coverage summary popup configuration
  summary = {
    auto_show = false,
    scope = "project", -- "project" or "file"
    show_files = true,
    max_files = 20,
    max_width = 120,
    max_height = 30,
    border = "rounded",
    zindex = 50,
    position = "center", -- "center" or "cursor"
    title = "Coverage Summary",
    thresholds = {
      covered = 80,
      partial = 50,
    },
  },

  -- NvimTree integration
  nvim_tree = {
    enabled = false,
    show_files = true,
    show_folders = true,
    format = "percent", -- "percent", or a string.format pattern
    fill_symbol = true, -- Show fill level symbol before percentage
    thresholds = nil, -- defaults to summary.thresholds when nil
  },

  -- Neo-tree integration
  neo_tree = {
    enabled = false,
    show_files = true,
    show_folders = true,
    format = "percent", -- "percent", or a string.format pattern
    fill_symbol = true, -- Show fill level symbol before percentage
    thresholds = nil, -- defaults to summary.thresholds when nil
  },
}

--- Check if file is a valid coverage file by detecting its format
---@param file_path string
---@return boolean
local function is_coverage_file(file_path)
  if vim.fn.filereadable(file_path) ~= 1 then
    return false
  end

  if utils.detect_format(file_path) then
    return true
  end

  -- Extension-based fallback
  local ext = file_path:match("%.([^.]+)$")
  local valid_exts = {
    lcov = true, info = true, json = true, xml = true,
    profdata = true, gcda = true, gcno = true,
    out = true,
  }

  return valid_exts[ext] or false
end

--- Find the first valid coverage file from a candidate list
---@param files string[]
---@param warn_on_invalid boolean
---@return string|nil
local function find_first_valid_coverage_file(files, warn_on_invalid)
  table.sort(files)

  local warned = false
  for _, file in ipairs(files) do
    if is_coverage_file(file) then
      return file
    elseif warn_on_invalid and not warned then
      vim.notify(
        string.format("Found '%s' but it's not a valid coverage file", vim.fn.fnamemodify(file, ":t")),
        vim.log.levels.WARN
      )
      warned = true
    end
  end

  return nil
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

  local project_roots = M.find_project_roots(buf_path)
  if not project_roots or #project_roots == 0 then
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

  local function search_coverage_in_root(project_root)
    for _, dir in ipairs(M.coverage_dirs) do
      local search_dir = project_root .. "/" .. dir

      if vim.fn.isdirectory(search_dir) == 1 then
        local candidates, seen = {}, {}

        -- Pattern-based discovery
        for _, pattern in ipairs(patterns) do
          local files = vim.fn.glob(search_dir .. "/" .. pattern, false, true)
          for _, file in ipairs(files or {}) do
            if vim.fn.filereadable(file) == 1 and not seen[file] then
              table.insert(candidates, file)
              seen[file] = true
            end
          end
        end

        local file = find_first_valid_coverage_file(candidates, true)
        if file then
          return file
        end

        -- Fallback: scan all files in the directory once patterns didn't match
        local entries = vim.fn.readdir(search_dir)
        local fallback_candidates = {}
        for _, name in ipairs(entries or {}) do
          local file_path = search_dir .. "/" .. name
          if vim.fn.filereadable(file_path) == 1 and not seen[file_path] then
            table.insert(fallback_candidates, file_path)
          end
        end

        file = find_first_valid_coverage_file(fallback_candidates, false)
        if file then
          return file
        end
      end
    end

    return nil
  end

  for _, project_root in ipairs(project_roots) do
    local file = search_coverage_in_root(project_root)
    if file then
      return file
    end
  end

  -- No coverage file found - notify user
  local searched_dirs = vim.tbl_flatten(vim.tbl_map(function(project_root)
    return vim.tbl_map(function(d)
      return project_root .. "/" .. d
    end, M.coverage_dirs)
  end, project_roots))
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
  local project_roots = M.find_project_roots(start_path)
  return project_roots and project_roots[1] or nil
end

--- Find all candidate project root directories from nearest to farthest
---@param start_path string
---@return string[]
function M.find_project_roots(start_path)
  if not start_path or start_path == "" then
    return {}
  end

  local path = vim.fn.fnamemodify(start_path, ":p:h")
  local roots = {}

  for _ = 1, 10 do
    for _, marker in ipairs(M.project_markers) do
      local marker_path = path .. "/" .. marker
      if vim.fn.isdirectory(marker_path) == 1 or vim.fn.filereadable(marker_path) == 1 then
        table.insert(roots, path)
        break
      end
    end
    local parent
    if vim.fs and vim.fs.dirname then
      parent = vim.fs.dirname(path)
    else
      parent = vim.fn.fnamemodify(path, ":h")
    end
    if parent == path or parent == "" then
      break
    end
    path = parent
  end

  return roots
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
    -- Dark theme: use lighter, pastel colors
    colors.covered = { bg = "#1a4d1a", fg = "NONE" }
    colors.uncovered = { bg = "#4d1a1a", fg = "NONE" }
    colors.partial = { bg = "#4d3d1a", fg = "NONE" }
  else
    -- Light theme: use lighter, pastel colors (slightly darker)
    colors.covered = { bg = "#d4f0d4", fg = "NONE" }
    colors.uncovered = { bg = "#f0d4d4", fg = "NONE" }
    colors.partial = { bg = "#f5e6cc", fg = "NONE" }
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

  -- Sign glyph highlight groups (foreground-only, no background).
  -- These are internal-only names generated here and not intended for
  -- user configuration. They are based on the primary line highlight
  -- group names with a "Sign" suffix.
  local covered_sign = (M.covered_hl or "CoverageCovered") .. "Sign"
  local uncovered_sign = (M.uncovered_hl or "CoverageUncovered") .. "Sign"
  local partial_sign = (M.partial_hl or "CoveragePartial") .. "Sign"

  M.covered_sign_hl = covered_sign
  M.uncovered_sign_hl = uncovered_sign
  M.partial_sign_hl = partial_sign

  vim.api.nvim_set_hl(0, covered_sign, {
    fg = covered_color.bg,
    bg = "NONE",
    bold = true,
    default = false,
  })

  vim.api.nvim_set_hl(0, uncovered_sign, {
    fg = uncovered_color.bg,
    bg = "NONE",
    bold = true,
    default = false,
  })

  vim.api.nvim_set_hl(0, partial_sign, {
    fg = partial_color.bg,
    bg = "NONE",
    bold = true,
    default = false,
  })

  vim.api.nvim_set_hl(0, (M.region_overlay and M.region_overlay.highlight_hl) or "CoverageRegionActive", {
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

  local has_hit_count_config = user_config.hit_count ~= nil

  -- Legacy config compatibility (ignored when hit_count is explicitly set)
  if not has_hit_count_config then
    if user_config.default_show_hit_count ~= nil then
      M.hit_count = M.hit_count or {}
      M.hit_count.show_by_default = user_config.default_show_hit_count and true or false
    end
    if user_config.show_hit_count ~= nil then
      M.hit_count = M.hit_count or {}
      if user_config.show_hit_count then
        if M.hit_count.display == nil or M.hit_count.display == "" then
          M.hit_count.display = "eol"
        end
      else
        M.hit_count.display = ""
      end
    end
  end

  if user_config.show_coverage_in_sign_column == nil then
    M.show_coverage_in_sign_column = false
  end

  -- Whitelist of valid config keys
  local valid_keys = {
    covered_hl = true,
    uncovered_hl = true,
    partial_hl = true,
    auto_adapt_colors = true,
    colors = true,
    hit_count = true,
    default_show_hit_count = true,
    show_hit_count = true,
    show_percentage = true,
    show_coverage_in_sign_column = true,
    show_branch_summary = true,
    enable_line_hl = true,
    center_on_navigate = true,
    auto_load = true,
    debug_notifications = true,
    llvm_binary_file = true,
    watch_debounce_ms = true,
    coverage_patterns = true,
    coverage_dirs = true,
    project_markers = true,
    cache_enabled = true,
    cache_dir = true,
    dev = true,
    branch_overlay = true,
    region_overlay = true,
    summary = true,
    nvim_tree = true,
    neo_tree = true,
  }

  for key, value in pairs(user_config) do
    if valid_keys[key] then
      -- Special handling: dev implies enabling debug notifications
      if key == "dev" then
        M.dev = value and true or false
        if M.dev then
          M.debug_notifications = true
        end
      elseif key == "default_show_hit_count" or key == "show_hit_count" then
        -- Already handled above for legacy compatibility
      else
        M[key] = value
      end
    elseif type(value) ~= "function" then
      -- Only warn about non-function keys (skip function references)
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
