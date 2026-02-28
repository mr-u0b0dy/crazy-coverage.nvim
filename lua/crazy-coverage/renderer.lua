-- Renderer module - handles extmark rendering of coverage data
local M = {}
local config = require("crazy-coverage.config")
local utils = require("crazy-coverage.utils")
local notify_once = vim.notify_once or vim.notify

-- Thin wrapper to centralize logging and avoid duplicate INFO popups
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
    if (br.hits or 0) > 0 then
      taken = taken + 1
    end
  end
  return total, taken
end

--- Determine highlight group based on coverage state
-- @param line_info table Line coverage information with 'hits' field
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
  
  -- Fall back to line coverage (hits > 0 means covered)
  local is_covered = (line_info.hits or 0) > 0
  return is_covered and config.covered_hl or config.uncovered_hl
end

-- NeoVim sign text must be at most 2 display cells; abbreviate safely
local function format_sign_text(sign_text)
  if sign_text == nil or sign_text == "" then
    return nil
  end

  local function display_width(str)
    return vim.fn.strdisplaywidth(str)
  end

  local text = tostring(sign_text)
  if text == "" then
    return nil
  end
  
  if display_width(text) <= 2 then
    return text
  end

  -- Try to abbreviate numeric values to fit in 2 display cells
  local num = tonumber(text)
  if num then
    if num >= 10000 then
      return ">9" -- overflow: exceeds thousands scale
    elseif num >= 1000 then
      return math.floor(num / 1000) .. "k" -- "1k" to "9k"
    elseif num >= 100 then
      return math.floor(num / 100) .. "+" -- "1+" to "9+", approximate hundreds
    else
      return tostring(math.floor(num))
    end
  end

  -- Fallback: truncate to first two display cells
  local truncated = ""
  for ch in text:gmatch(".") do
    local next_text = truncated .. ch
    if display_width(next_text) > 2 then
      break
    end
    truncated = next_text
  end
  
  return truncated ~= "" and truncated or nil
end

-- Exposed for testing
M._format_sign_text = format_sign_text

M.namespace = vim.api.nvim_create_namespace("coverage_plugin")
M.region_overlay_namespace = vim.api.nvim_create_namespace("coverage_region_overlay")

local function clear_region_highlight(buf)
  if buf and vim.api.nvim_buf_is_valid(buf) then
    vim.api.nvim_buf_clear_namespace(buf, M.region_overlay_namespace, 0, -1)
  end
end

local function set_region_highlight(buf, region)
  clear_region_highlight(buf)
  if not region or not buf or not vim.api.nvim_buf_is_valid(buf) then
    return
  end

  local start_row = region.line - 1
  local start_col = math.max(region.start_col or 0, 0)
  local end_col = math.max(region.end_col or (start_col + 1), start_col + 1)
  local hl = region.hl or config.partial_hl

  pcall(vim.api.nvim_buf_set_extmark, buf, M.region_overlay_namespace, start_row, start_col, {
    end_col = end_col,
    hl_group = hl,
    priority = 220,
    strict = false,
  })
end

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
---@param coverage_data table -- Coverage data keyed by file path
---@param project_root string|nil -- Project root for context (from cache)
function M.render(coverage_data, project_root)
  if not coverage_data then
    error("coverage_data is required")
  end
  
  if type(coverage_data) ~= "table" then
    error("coverage_data must be a table")
  end

  if project_root then
    notify(string.format("RENDER: Using project root: %s", project_root), vim.log.levels.DEBUG)
  end

  local rendered_count = 0
  local file_count = 0
  for _ in pairs(coverage_data) do
    file_count = file_count + 1
  end
  
  notify(string.format("RENDER: Starting render for %d files", file_count), vim.log.levels.DEBUG)
  
  for file_path, file_entry in pairs(coverage_data) do
    if file_entry then
      notify(string.format("RENDER: File path: %s (lines: %d)", file_path, #(file_entry.lines or {})), vim.log.levels.DEBUG)
      local buf = utils.get_buffer_by_path(file_path)
      if buf then
        notify(string.format("RENDER: Found buffer %d, rendering %d lines", buf, #(file_entry.lines or {})), vim.log.levels.DEBUG)
        local ok, err = pcall(M.render_file, buf, file_entry)
        if ok then
          rendered_count = rendered_count + 1
        else
          notify("Failed to render " .. file_path .. ": " .. tostring(err), vim.log.levels.WARN)
        end
      else
        notify(string.format("RENDER: No buffer found for %s", file_path), vim.log.levels.DEBUG)
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
    notify("No line or branch data for " .. (file_entry.path or "unknown"), vim.log.levels.WARN)
    return -- No data at all, skip silently
  end

  -- Clear previous marks for this buffer
  M.clear_buffer(buf)
  
  -- Track partial coverage statistics
  local partial_lines = {}

  -- Create a map of line coverage for fast lookup
  local line_map = {}
  for _, line_info in ipairs(file_entry.lines or {}) do
    line_map[line_info.line] = line_info
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
    rendered_lines[line_info.line] = true
  end
  
  -- Add lines from branch coverage that don't have line data
  for line_num, _ in pairs(branch_map) do
    if not rendered_lines[line_num] then
      -- Create synthetic line entry for branch-only coverage
      local branches = branch_map[line_num]
      local total, taken = calculate_branch_stats(branches)
      
      table.insert(lines_to_render, {
        line = line_num,
        hits = nil,  -- No line hit count, only branch info
      })
    end
  end

  -- Render each line
  for _, line_info in ipairs(lines_to_render) do
    local line_num = line_info.line
    local hit_count = line_info.hits
    local branches = branch_map[line_num]
    
    -- Calculate branch statistics
    local branch_total, branch_taken = calculate_branch_stats(branches)
    
    -- Determine highlight group
    local hl_group = get_highlight_group(line_info, branches, branch_total, branch_taken)
    
    -- Track partial coverage for summary
    if branches and branch_total > 0 and branch_taken > 0 and branch_taken < branch_total then
      table.insert(partial_lines, { line = line_num, taken = branch_taken, total = branch_total })
      notify(
        string.format("PARTIAL: Line %d in %s has partial branch coverage (%d/%d branches taken)", 
          line_num, file_entry.path or "unknown", branch_taken, branch_total),
        vim.log.levels.DEBUG
      )
    end

    -- Build virtual text (only for non-sign display modes)
    local virt_text = {}
    local hit_count_display = config.hit_count and config.hit_count.display or "eol"
    if hit_count_display ~= "sign" and hit_count_display ~= "" and hit_count then
      table.insert(virt_text, { " " .. hit_count, hl_group })
    end

    if config.show_percentage and hit_count and hit_count > 0 then
      table.insert(virt_text, { " (hit)", hl_group })
    end

    -- Place extmark on line with virtual text, line highlighting, and sign text
    local should_render = #virt_text > 0 or config.enable_line_hl or (hit_count_display == "sign" and hit_count)
    
    if should_render then
      local extmark_opts = {
        priority = 200,
        hl_eol = false,
        strict = false,
      }
      
      -- Add virtual text if present
      if #virt_text > 0 then
        extmark_opts.virt_text = virt_text
        -- Only set virt_text_pos if it's a valid position (not "sign" or empty)
        if hit_count_display == "eol" or hit_count_display == "inline" or hit_count_display == "overlay" or hit_count_display == "right_align" then
          extmark_opts.virt_text_pos = hit_count_display
        else
          -- Default to eol for branch info when not in a valid display mode
          extmark_opts.virt_text_pos = "eol"
        end
      end
      
      -- Add line highlighting if enabled
      if config.enable_line_hl then
        extmark_opts.line_hl_group = hl_group
      end
      
      -- Add sign text with hit count in sign column (left gutter)
      if hit_count_display == "sign" and hit_count then
        local sign_text
        if type(config.hit_count.sign_text_format) == "function" then
          sign_text = config.hit_count.sign_text_format(hit_count)
        elseif type(config.hit_count.sign_text_format) == "string" then
          sign_text = string.format(config.hit_count.sign_text_format, hit_count)
        else
          -- Fallback: show exact hit count
          sign_text = tostring(hit_count)
        end
        sign_text = format_sign_text(sign_text)
        -- Only set sign_text if it's a valid non-empty string (Neovim requirement)
        if sign_text and type(sign_text) == "string" and sign_text ~= "" then
          extmark_opts.sign_text = sign_text
          extmark_opts.sign_hl_group = hl_group
        end
      end
      
      local ok, err = pcall(vim.api.nvim_buf_set_extmark, buf, M.namespace, line_num - 1, 0, extmark_opts)
      if not ok then
        notify("Failed to set extmark on line " .. line_num .. ": " .. tostring(err), vim.log.levels.ERROR)
      end
    end
  end
  
  -- Report partial coverage summary
  if #partial_lines > 0 then
    local lines_str = {}
    for _, info in ipairs(partial_lines) do
      table.insert(lines_str, string.format("%d(%d/%d)", info.line, info.taken, info.total))
    end
    notify(string.format("PARTIAL COVERAGE: %s has %d lines with partial branch coverage: %s", 
      file_entry.path or "unknown", #partial_lines, table.concat(lines_str, ", ")), vim.log.levels.DEBUG)
  end
end

--- Set up highlight groups
function M.setup()
  config.setup_highlights()
end

-- Summary popup state
local _summary_popup = {
  win = nil,
  buf = nil,
  previous_summary = nil,
}

local function close_summary_popup()
  if _summary_popup.win and vim.api.nvim_win_is_valid(_summary_popup.win) then
    pcall(vim.api.nvim_win_close, _summary_popup.win, true)
  end
  if _summary_popup.buf and vim.api.nvim_buf_is_valid(_summary_popup.buf) then
    pcall(vim.api.nvim_buf_delete, _summary_popup.buf, { force = true })
  end
  _summary_popup.win = nil
  _summary_popup.buf = nil
  -- Don't clear previous_summary here, let render_summary handle it
end

local function pick_percent_hl(percent, thresholds)
  local covered = (thresholds and thresholds.covered) or 80
  local partial = (thresholds and thresholds.partial) or 50
  if percent >= covered then
    return config.covered_hl
  elseif percent >= partial then
    return config.partial_hl
  end
  return config.uncovered_hl
end

local function truncate_line(text, max_width)
  if max_width <= 0 then
    return ""
  end
  if vim.fn.strdisplaywidth(text) <= max_width then
    return text
  end

  local suffix = "..."
  if max_width <= #suffix then
    return text:sub(1, max_width)
  end

  local target = max_width - #suffix
  local out = ""
  for ch in text:gmatch(".") do
    if vim.fn.strdisplaywidth(out .. ch) > target then
      break
    end
    out = out .. ch
  end

  return out .. suffix
end

--- Compute boolean combinations for a small power-of-two branch group
-- @param branches table Array of branch entries for a line
-- @param enable boolean Whether to compute combos (driven by config)
-- @return combos, combos_by_branch, covered, missing
local function compute_branch_combos(branches, enable)
  if not enable or not branches or #branches <= 1 then
    return nil, nil, nil, nil
  end

  local total = #branches
  local bits = 1
  while (2 ^ bits) < total do
    bits = bits + 1
  end

  if bits > 8 then
    return nil, nil, nil, nil
  end

  local combos = {}
  local combos_by_branch = {}
  local covered = {}
  local missing = {}
  for bi = 1, #branches do combos_by_branch[bi] = {} end

  for i = 1, total do
    local idx = i - 1
    local s = ""
    for bidx = bits - 1, 0, -1 do
      local pow = 2 ^ bidx
      local bit = math.floor(idx / pow) % 2
      s = s .. (bit == 1 and "T" or "F")
    end
    combos[i] = s
    combos_by_branch[i] = { s }
    local br = branches[i]
    if br and (br.hits or 0) > 0 then
      table.insert(covered, s)
    else
      table.insert(missing, s)
    end
  end

  return combos, combos_by_branch, covered, missing
end

--- Render coverage summary popup
---@param summary table
function M.render_summary(summary)
  if not summary then
    return
  end

  -- Save previous summary BEFORE closing (which would clear it)
  local prev_summary = _summary_popup.previous_summary
  
  close_summary_popup()

  local cfg = config.summary or {}
  local title = cfg.title or "Coverage Summary"
  local scope_label = summary.scope == "file" and "File" or "Project"
  local lines = {}
  local highlights = {}

  table.insert(lines, string.format("%s - %s", title, scope_label))
  table.insert(highlights, {{ hl = "Title", col_start = 0, col_end = -1 }})

  local totals = summary.totals or {}
  local percent = totals.percent or 0
  
  -- Build stats lines with inline highlights
  if totals.total_files then
    table.insert(lines, string.format("Files: %d  Total Lines: %d", totals.total_files, totals.total_lines or 0))
    table.insert(highlights, {})
  else
    table.insert(lines, string.format("Total Lines: %d", totals.total_lines or 0))
    table.insert(highlights, {})
  end
  
  table.insert(lines, "")
  table.insert(highlights, {})
  
  -- Coverage breakdown with colored percentages on separate lines
  local covered_pct = totals.total_lines > 0 and (totals.covered_lines / totals.total_lines * 100) or 0
  local uncovered_pct = totals.total_lines > 0 and (totals.uncovered_lines / totals.total_lines * 100) or 0
  local partial_pct = totals.total_lines > 0 and (totals.partial_lines / totals.total_lines * 100) or 0
  
  -- Covered line
  local covered_line = string.format("  Covered:   %3d lines (%.1f%%)", totals.covered_lines or 0, covered_pct)
  table.insert(lines, covered_line)
  local covered_pct_str = string.format("%.1f%%", covered_pct)
  local covered_pos = covered_line:find(covered_pct_str, 1, true)
  if covered_pos then
    table.insert(highlights, {{ hl = config.covered_hl, col_start = covered_pos - 1, col_end = covered_pos + #covered_pct_str - 1 }})
  else
    table.insert(highlights, {})
  end
  
  -- Uncovered line
  local uncovered_line = string.format("  Uncovered: %3d lines (%.1f%%)", totals.uncovered_lines or 0, uncovered_pct)
  table.insert(lines, uncovered_line)
  local uncovered_pct_str = string.format("%.1f%%", uncovered_pct)
  local uncovered_pos = uncovered_line:find(uncovered_pct_str, 1, true)
  if uncovered_pos then
    table.insert(highlights, {{ hl = config.uncovered_hl, col_start = uncovered_pos - 1, col_end = uncovered_pos + #uncovered_pct_str - 1 }})
  else
    table.insert(highlights, {})
  end
  
  -- Partial line
  local partial_line = string.format("  Partial:   %3d lines (%.1f%%)", totals.partial_lines or 0, partial_pct)
  table.insert(lines, partial_line)
  local partial_pct_str = string.format("%.1f%%", partial_pct)
  local partial_pos = partial_line:find(partial_pct_str, 1, true)
  if partial_pos then
    table.insert(highlights, {{ hl = config.partial_hl, col_start = partial_pos - 1, col_end = partial_pos + #partial_pct_str - 1 }})
  else
    table.insert(highlights, {})
  end
  
  table.insert(lines, "")
  table.insert(highlights, {})
  
  table.insert(lines, string.format("Overall Coverage: %.2f%%", percent))
  table.insert(highlights, {{ hl = pick_percent_hl(percent, cfg.thresholds), col_start = 18, col_end = -1 }})

  if summary.file_path then
    table.insert(lines, "")
    table.insert(highlights, {})
    table.insert(lines, "File: " .. summary.file_path)
    table.insert(highlights, {})
    table.insert(lines, "")
    table.insert(highlights, {})
    if summary.from_project then
      table.insert(lines, "(press 'b' to go back, 'q' to close)")
    else
      table.insert(lines, "(press 'q' to close)")
    end
    table.insert(highlights, {})
  end

  local file_line_offset = #lines + 1
  if summary.scope == "project" and cfg.show_files and summary.files and #summary.files > 0 then
    table.insert(lines, "")
    table.insert(highlights, {})
    table.insert(lines, "Files (press Enter to view, q to close):")
    table.insert(highlights, {{ hl = "Title", col_start = 0, col_end = -1 }})
    table.insert(lines, "Coverage  Cov/Unc/Part  Total  File")
    table.insert(highlights, {})

    for _, file_stat in ipairs(summary.files) do
      local line = string.format(
        "  %5.1f%%  %3d/%3d/%3d  %5d  %s",
        file_stat.percent or 0,
        file_stat.covered_lines or 0,
        file_stat.uncovered_lines or 0,
        file_stat.partial_lines or 0,
        file_stat.total_lines or 0,
        file_stat.display_path or file_stat.path or "(unknown)"
      )
      table.insert(lines, line)
      -- Color just the percentage at the start
      table.insert(highlights, {{ hl = pick_percent_hl(file_stat.percent or 0, cfg.thresholds), col_start = 2, col_end = 8 }})
    end
  end

  local max_width = cfg.max_width or 80
  local max_line_width = 0
  for i, line in ipairs(lines) do
    local truncated = truncate_line(line, max_width)
    lines[i] = truncated
    local width = vim.fn.strdisplaywidth(truncated)
    if width > max_line_width then
      max_line_width = width
    end
  end

  local height = #lines
  if cfg.max_height and height > cfg.max_height then
    height = cfg.max_height
    local trimmed = {}
    local trimmed_hls = {}
    for i = 1, height - 1 do
      table.insert(trimmed, lines[i])
      table.insert(trimmed_hls, highlights[i])
    end
    table.insert(trimmed, "...")
    table.insert(trimmed_hls, {})
    lines = trimmed
    highlights = trimmed_hls
  end

  local width = math.max(max_line_width, 20)

  local summary_buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_option(summary_buf, "bufhidden", "wipe")
  vim.api.nvim_buf_set_option(summary_buf, "buftype", "nofile")
  vim.api.nvim_buf_set_option(summary_buf, "swapfile", false)
  vim.api.nvim_buf_set_option(summary_buf, "modifiable", true)
  vim.api.nvim_buf_set_lines(summary_buf, 0, -1, false, lines)
  vim.api.nvim_buf_set_option(summary_buf, "modifiable", false)
  vim.api.nvim_buf_set_option(summary_buf, "filetype", "crazy-coverage-summary")

  -- Apply inline highlights
  for i, line_hls in ipairs(highlights) do
    if line_hls and #line_hls > 0 then
      for _, hl_info in ipairs(line_hls) do
        pcall(vim.api.nvim_buf_add_highlight, summary_buf, 0, hl_info.hl, i - 1, hl_info.col_start, hl_info.col_end)
      end
    end
  end
  
  -- Store summary data and file offset for interactivity
  vim.b[summary_buf].coverage_summary = summary
  vim.b[summary_buf].file_line_offset = file_line_offset
  
  -- Manage previous summary for back navigation
  if summary.from_project and prev_summary then
    -- Viewing file details from project: keep the previous (project) summary
    _summary_popup.previous_summary = prev_summary
  elseif not summary.from_project and summary.scope == "project" then
    -- Back at project view: clear previous summary
    _summary_popup.previous_summary = nil
  elseif prev_summary and not summary.from_project then
    -- Other transitions: preserve previous summary
    _summary_popup.previous_summary = prev_summary
  end

  local opts
  if cfg.position == "cursor" then
    local cur_win = vim.api.nvim_get_current_win()
    local cursor = vim.api.nvim_win_get_cursor(cur_win)
    local win_top_line = vim.fn.line("w0")
    local cursor_row = cursor[1] - win_top_line
    if cursor_row < 0 then
      cursor_row = 0
    end
    opts = {
      relative = "win",
      win = cur_win,
      anchor = "NW",
      row = cursor_row + 1,
      col = 0,
      width = width,
      height = height,
      style = "minimal",
      border = cfg.border or "rounded",
      zindex = cfg.zindex or 50,
      noautocmd = true,
      focusable = true,
    }
  else
    local ui = vim.api.nvim_list_uis()[1]
    local total_width = ui and ui.width or vim.o.columns
    local total_height = ui and ui.height or vim.o.lines
    local row = math.floor((total_height - height) / 2)
    local col = math.floor((total_width - width) / 2)
    if row < 0 then row = 0 end
    if col < 0 then col = 0 end
    opts = {
      relative = "editor",
      row = row,
      col = col,
      width = width,
      height = height,
      style = "minimal",
      border = cfg.border or "rounded",
      zindex = cfg.zindex or 50,
      noautocmd = true,
      focusable = true,
    }
  end

  local summary_win = vim.api.nvim_open_win(summary_buf, true, opts)
  _summary_popup.win = summary_win
  _summary_popup.buf = summary_buf

  vim.keymap.set("n", "q", function()
    M.close_summary()
  end, { buffer = summary_buf, silent = true, nowait = true })
  
  vim.keymap.set("n", "<CR>", function()
    if not vim.api.nvim_win_is_valid(summary_win) then return end
    local line_num = vim.api.nvim_win_get_cursor(summary_win)[1]
    local offset = vim.b[summary_buf].file_line_offset or 0
    local summary_data = vim.b[summary_buf].coverage_summary
    
    if summary_data and summary_data.scope == "project" and summary_data.files then
      local file_idx = line_num - offset - 2  -- -2 for header lines
      if file_idx >= 1 and file_idx <= #summary_data.files then
        local file_stat = summary_data.files[file_idx]
        -- Store previous summary before rendering new one
        _summary_popup.previous_summary = vim.deepcopy(summary_data)
        -- Build file summary
        local file_summary = {
          scope = "file",
          totals = {
            total_lines = file_stat.total_lines,
            covered_lines = file_stat.covered_lines,
            uncovered_lines = file_stat.uncovered_lines,
            partial_lines = file_stat.partial_lines,
            percent = file_stat.percent,
          },
          file_path = file_stat.display_path or file_stat.path,
          from_project = true,
        }
        M.render_summary(file_summary)
      end
    end
  end, { buffer = summary_buf, silent = true, nowait = true })
  
  vim.keymap.set("n", "b", function()
    local prev = _summary_popup.previous_summary
    if prev then
      -- Don't clear it yet - let render_summary handle it
      M.render_summary(prev)
    end
  end, { buffer = summary_buf, silent = true, nowait = true })
end

--- Close summary popup
function M.close_summary()
  close_summary_popup()
  -- Clear previous summary when explicitly closing
  _summary_popup.previous_summary = nil
end

-- Branch overlay state (per window)
local _branch_overlay = {
  wins = {}, -- [win] = { win = win_id, buf = buf_id }
}

-- Region overlay state (per window)
local _region_overlay = {
  wins = {}, -- [win] = { win = win_id, buf = buf_id, source_buf = source_buf }
}

--- Build lines for branch overlay
--- @param file_entry table
--- @param current_line number|nil Current cursor line (only show this line if provided)
--- @return table lines, table highlights
local function build_branch_overlay_lines(file_entry, current_line)
  local branch_map = {}
  for _, br in ipairs(file_entry.branches or {}) do
    local line = br.line or br.line_num
    if type(line) == "number" then
      if not branch_map[line] then
        branch_map[line] = {}
      end
      local hits = br.hits
      if hits == nil then
        hits = br.hit_count
      end
      hits = hits or 0
      local id = br.id or br.branch_id or br.col or #branch_map[line] + 1
      table.insert(branch_map[line], {
        id = id,
        hits = hits,
      })
    end
  end

  local lines, hls = {}, {}

  -- Title line (will be updated with summary, default neutral color)
  local title = (config.branch_overlay and config.branch_overlay.title) or "Branch Coverage"
  table.insert(lines, title)
  table.insert(hls, "Normal") -- use Normal highlight for uncolored title

  -- Filter to current line if specified
  local sorted = {}
  if current_line and branch_map[current_line] then
    table.insert(sorted, current_line)
  elseif not current_line then
    -- Show all lines if no current line specified
    for ln, _ in pairs(branch_map) do
      table.insert(sorted, ln)
    end
    table.sort(sorted)
  end

  for _, ln in ipairs(sorted) do
    local branches = branch_map[ln]
    local total, taken = 0, 0
    total = #branches
    for _, b in ipairs(branches) do
      if (b.hits or 0) > 0 then
        taken = taken + 1
      end
    end

    -- Update title to show summary with percentage
    local percentage = total > 0 and math.floor((taken / total) * 100) or 0
    lines[1] = string.format("Branch Coverage: %d/%d taken (%d%%)", taken, total, percentage)

    -- Pre-compute boolean combinations and per-branch markers if requested.
    local combos, combos_by_branch, covered, missing = compute_branch_combos(branches, config.show_branch_summary)

    -- Add individual branch lines.
    -- If we computed a list of combinations that map to branch entries (combos),
    -- show the corresponding combination next to the branch id like
    -- "Branch <id> (<comb>) : <hits>". Otherwise fall back to the original format.
    for bi, b in ipairs(branches) do
      local hit_count = b.hits or 0
      local branch_line

      -- Prefer a representative combination from combos_by_branch (first match),
      -- fall back to the naive combos[bi] mapping if present.
      local rep = nil
      if combos_by_branch and combos_by_branch[bi] and #combos_by_branch[bi] > 0 then
        rep = combos_by_branch[bi][1]
      elseif combos and combos[bi] then
        rep = combos[bi]
      end

      local display_branch_num = b.id or bi
      if rep then
        branch_line = string.format("Branch %s (%s) : %d", tostring(display_branch_num), rep, hit_count)
      else
        branch_line = string.format("Branch %s : %d", tostring(display_branch_num), hit_count)
      end

      table.insert(lines, branch_line)

      -- Color based on hit count: green if > 0, red if 0
      local hl = hit_count > 0 and config.covered_hl or config.uncovered_hl
      table.insert(hls, hl)
    end

    -- Note: global combinations summary (Combinations/Covered/Missing)
    -- intentionally omitted to keep the overlay compact; per-branch
    -- combination is shown next to each branch line when available.
  end

  if #sorted == 0 then
    if current_line then
      table.insert(lines, string.format("No branch data for line %d", current_line))
    else
      table.insert(lines, "No branch data for this file")
    end
    table.insert(hls, config.uncovered_hl)
  end

  return lines, hls
end

--- Render branch overlay for the current window
--- @param buf number
--- @param file_entry table
function M.render_branch_overlay(buf, file_entry)
  if not buf or not vim.api.nvim_buf_is_valid(buf) then
    return
  end
  if not file_entry then
    return
  end

  local cur_win = vim.api.nvim_get_current_win()
  local cursor_line = vim.api.nvim_win_get_cursor(cur_win)[1]
  local lines, hls = build_branch_overlay_lines(file_entry, cursor_line)

  -- Create scratch buffer
  local overlay_buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_option(overlay_buf, "bufhidden", "wipe")
  vim.api.nvim_buf_set_option(overlay_buf, "modifiable", true)
  vim.api.nvim_buf_set_lines(overlay_buf, 0, -1, false, lines)
  vim.api.nvim_buf_set_option(overlay_buf, "modifiable", false)

  -- Apply per-line highlights
  for i, hl in ipairs(hls) do
    pcall(vim.api.nvim_buf_add_highlight, overlay_buf, 0, hl, i - 1, 0, -1)
  end

  local cfg = config.branch_overlay or {}
  local win_width = vim.api.nvim_win_get_width(cur_win)
  local height = math.min(cfg.max_height or 12, #lines)

  -- Position overlay above or below the cursor line based on available space
  local win_height = vim.api.nvim_win_get_height(cur_win)
  local win_top_line = vim.fn.line("w0")
  local cursor_screen_row = cursor_line - win_top_line
  
  -- Calculate space above and below cursor
  local space_above = cursor_screen_row  -- rows from top to cursor
  local space_below = win_height - cursor_screen_row - 1  -- rows from cursor+1 to bottom
  
  local row
  if space_below >= height then
    -- Place below the cursor line (cursor_screen_row + 1)
    row = cursor_screen_row + 1
  else
    -- No space below, place above the cursor line
    -- Overlay should end at cursor_screen_row - 1, so row = cursor_screen_row - height
    row = cursor_screen_row - height
  end

  local opts = {
    relative = "win",
    win = cur_win,
    anchor = "NW",
    row = row,
    col = 0,
    width = win_width,
    height = height,
    style = "minimal",
    border = cfg.border or "rounded",
    zindex = cfg.zindex or 45,
    noautocmd = true,
    focusable = false,
  }

  local overlay_win = vim.api.nvim_open_win(overlay_buf, false, opts)
  local augroup_name = "CoverageBranchOverlay_" .. cur_win
  _branch_overlay.wins[cur_win] = {
    win = overlay_win,
    buf = overlay_buf,
    cursor_line = cursor_line,
    augroup = augroup_name,
  }
  
  -- Auto-close overlay when cursor moves or the source window loses focus
  vim.api.nvim_create_augroup(augroup_name, { clear = true })
  vim.api.nvim_create_autocmd("CursorMoved", {
    group = augroup_name,
    buffer = buf,
    callback = function()
      if not vim.api.nvim_win_is_valid(cur_win) then
        M.close_branch_overlay(cur_win)
        return
      end
      local new_line = vim.api.nvim_win_get_cursor(cur_win)[1]
      if new_line ~= cursor_line then
        M.close_branch_overlay(cur_win)
      end
    end,
  })
  vim.api.nvim_create_autocmd({ "WinLeave", "WinClosed" }, {
    group = augroup_name,
    callback = function(args)
      -- WinClosed passes the closed win id as a string in args.match
      local closed_win = (args.event == "WinClosed") and tonumber(args.match) or nil
      if closed_win == cur_win or (args.event == "WinLeave" and vim.api.nvim_get_current_win() == cur_win) then
        M.close_branch_overlay(cur_win)
      end
    end,
  })
end

--- Close branch overlay for a specific window (current if nil)
--- @param win number|nil
function M.close_branch_overlay(win)
  win = win or vim.api.nvim_get_current_win()
  local entry = _branch_overlay.wins[win]
  if entry then
    if entry.win and vim.api.nvim_win_is_valid(entry.win) then
      pcall(vim.api.nvim_win_close, entry.win, true)
    end
    if entry.buf and vim.api.nvim_buf_is_valid(entry.buf) then
      pcall(vim.api.nvim_buf_delete, entry.buf, { force = true })
    end
    -- Clean up autocmd group safely
    if entry.augroup then
      pcall(vim.api.nvim_del_augroup_by_name, entry.augroup)
    end
    _branch_overlay.wins[win] = nil
  end
end

--- Close all branch overlays
function M.close_all_branch_overlays()
  for win, _ in pairs(_branch_overlay.wins) do
    M.close_branch_overlay(win)
  end
end

--- Check if branch overlay is open for a window
--- @param win number|nil
--- @return boolean
function M.is_branch_overlay_open(win)
  win = win or vim.api.nvim_get_current_win()
  local entry = _branch_overlay.wins[win]
  return entry ~= nil and entry.win and vim.api.nvim_win_is_valid(entry.win)
end

--- Check if a window is a branch overlay window
--- @param win number|nil
--- @return boolean
function M.is_branch_overlay_win(win)
  win = win or vim.api.nvim_get_current_win()
  for _, entry in pairs(_branch_overlay.wins) do
    if entry.win == win then
      return true
    end
  end
  return false
end

local function get_llvm_region_at_cursor(file_entry, buf, cursor_line, cursor_col0)
  if not file_entry or file_entry.source_format ~= "llvm_json" then
    return nil
  end
  if not buf or not vim.api.nvim_buf_is_valid(buf) then
    return nil
  end

  local regions = {}
  for _, br in ipairs(file_entry.branches or {}) do
    local line = br.line or br.line_num
    if line == cursor_line and not br.is_branch and type(br.col) == "number" and br.col > 0 then
      table.insert(regions, {
        line = line,
        col = br.col,
        end_col = br.end_col,
        hits = br.hits or br.hit_count or 0,
      })
    end
  end

  if #regions == 0 then
    return nil
  end

  table.sort(regions, function(a, b)
    return (a.col or 0) < (b.col or 0)
  end)

  local line_text = vim.api.nvim_buf_get_lines(buf, cursor_line - 1, cursor_line, false)[1] or ""
  local line_end_col0 = #line_text

  for i, region in ipairs(regions) do
    local start_col0 = math.max((region.col or 1) - 1, 0)
    local end_col0

    if type(region.end_col) == "number" and region.end_col > 0 then
      end_col0 = math.max(region.end_col - 1, start_col0 + 1)
    elseif regions[i + 1] and type(regions[i + 1].col) == "number" then
      end_col0 = math.max(regions[i + 1].col - 1, start_col0 + 1)
    else
      end_col0 = math.max(line_end_col0, start_col0 + 1)
    end

    if cursor_col0 >= start_col0 and cursor_col0 < end_col0 then
      return {
        line = cursor_line,
        start_col = start_col0,
        end_col = end_col0,
        hits = region.hits,
      }
    end
  end

  return nil
end

local function build_region_overlay_lines(region)
  local cfg = config.region_overlay or {}
  local title = cfg.title or "Region Coverage"
  local lines = {
    title,
    string.format("Line %d, Col %d-%d", region.line, region.start_col + 1, region.end_col),
    string.format("Hit Count: %d", region.hits or 0),
  }

  local hls = {
    "Normal",
    "Normal",
    (region.hits or 0) > 0 and config.covered_hl or config.uncovered_hl,
  }

  return lines, hls
end

function M.render_region_overlay(buf, file_entry)
  if not buf or not vim.api.nvim_buf_is_valid(buf) or not file_entry then
    return false
  end

  local cur_win = vim.api.nvim_get_current_win()
  local cursor = vim.api.nvim_win_get_cursor(cur_win)
  local cursor_line = cursor[1]
  local cursor_col0 = cursor[2] or 0

  local region = get_llvm_region_at_cursor(file_entry, buf, cursor_line, cursor_col0)
  if not region then
    M.close_region_overlay(cur_win)
    clear_region_highlight(buf)
    return false
  end

  if M.is_region_overlay_open(cur_win) then
    M.close_region_overlay(cur_win)
  end

  set_region_highlight(buf, {
    line = region.line,
    start_col = region.start_col,
    end_col = region.end_col,
    hl = (config.region_overlay and config.region_overlay.highlight_hl) or "CoverageRegionActive",
  })

  local lines, hls = build_region_overlay_lines(region)
  local overlay_buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_option(overlay_buf, "bufhidden", "wipe")
  vim.api.nvim_buf_set_option(overlay_buf, "modifiable", true)
  vim.api.nvim_buf_set_lines(overlay_buf, 0, -1, false, lines)
  vim.api.nvim_buf_set_option(overlay_buf, "modifiable", false)

  for i, hl in ipairs(hls) do
    pcall(vim.api.nvim_buf_add_highlight, overlay_buf, 0, hl, i - 1, 0, -1)
  end

  local cfg = config.region_overlay or {}
  local win_width = vim.api.nvim_win_get_width(cur_win)
  local width = math.min(win_width, 40)
  local height = math.min(cfg.max_height or 8, #lines)

  local win_height = vim.api.nvim_win_get_height(cur_win)
  local win_top_line = vim.fn.line("w0")
  local cursor_screen_row = cursor_line - win_top_line
  local row = (win_height - cursor_screen_row - 1) >= height and (cursor_screen_row + 1) or (cursor_screen_row - height)

  local opts = {
    relative = "win",
    win = cur_win,
    anchor = "NW",
    row = row,
    col = 0,
    width = width,
    height = height,
    style = "minimal",
    border = cfg.border or "rounded",
    zindex = cfg.zindex or 46,
    noautocmd = true,
    focusable = false,
  }

  local overlay_win = vim.api.nvim_open_win(overlay_buf, false, opts)
  local augroup_name = "CoverageRegionOverlay_" .. cur_win
  _region_overlay.wins[cur_win] = {
    win = overlay_win,
    buf = overlay_buf,
    source_buf = buf,
    augroup = augroup_name,
  }

  vim.api.nvim_create_augroup(augroup_name, { clear = true })
  vim.api.nvim_create_autocmd("CursorMoved", {
    group = augroup_name,
    buffer = buf,
    callback = function()
      if not vim.api.nvim_win_is_valid(cur_win) then
        M.close_region_overlay(cur_win)
        return
      end
      local ok, err = pcall(M.render_region_overlay, buf, file_entry)
      if not ok then
        notify("Region overlay render failed: " .. tostring(err), vim.log.levels.WARN)
      end
    end,
  })

  vim.api.nvim_create_autocmd({ "WinLeave", "WinClosed" }, {
    group = augroup_name,
    callback = function(args)
      local closed_win = (args.event == "WinClosed") and tonumber(args.match) or nil
      if closed_win == cur_win or (args.event == "WinLeave" and vim.api.nvim_get_current_win() == cur_win) then
        M.close_region_overlay(cur_win)
      end
    end,
  })

  return true
end

function M.close_region_overlay(win)
  win = win or vim.api.nvim_get_current_win()
  local entry = _region_overlay.wins[win]
  if entry then
    if entry.win and vim.api.nvim_win_is_valid(entry.win) then
      pcall(vim.api.nvim_win_close, entry.win, true)
    end
    if entry.buf and vim.api.nvim_buf_is_valid(entry.buf) then
      pcall(vim.api.nvim_buf_delete, entry.buf, { force = true })
    end
    if entry.augroup then
      pcall(vim.api.nvim_del_augroup_by_name, entry.augroup)
    end
    if entry.source_buf then
      clear_region_highlight(entry.source_buf)
    end
    _region_overlay.wins[win] = nil
  end
end

function M.close_all_region_overlays()
  for win, _ in pairs(_region_overlay.wins) do
    M.close_region_overlay(win)
  end
end

function M.is_region_overlay_open(win)
  win = win or vim.api.nvim_get_current_win()
  local entry = _region_overlay.wins[win]
  return entry ~= nil and entry.win and vim.api.nvim_win_is_valid(entry.win)
end

return M
