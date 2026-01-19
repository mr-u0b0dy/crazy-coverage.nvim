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
  if sign_text == nil then
    return ""
  end

  local function display_width(str)
    return vim.fn.strdisplaywidth(str)
  end

  local text = tostring(sign_text)
  if display_width(text) <= 2 then
    return text
  end

  -- Try to abbreviate numeric values
  local num = tonumber(text)
  if num then
    if num >= 1000000 then
      return "9+" -- cap large numbers
    elseif num >= 1000 then
      return "1k"
    elseif num >= 100 then
      return tostring(math.floor(num / 10)) .. "0" -- e.g., 123 -> "120"
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
  return truncated
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
        -- Only set sign_text if it's a non-empty string (Neovim requirement)
        if sign_text and sign_text ~= "" then
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

-- Branch overlay state (per window)
local _branch_overlay = {
  wins = {}, -- [win] = { win = win_id, buf = buf_id }
}

--- Build lines for branch overlay
--- @param file_entry table
--- @param current_line number|nil Current cursor line (only show this line if provided)
--- @return table lines, table highlights -- lines of text, and per-line highlight groups
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
      table.insert(branch_map[line], { id = id, hits = hits })
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

    -- Add individual branch lines
    for _, b in ipairs(branches) do
      local branch_line = string.format("Branch %s : %d", tostring(b.id), b.hits or 0)
      table.insert(lines, branch_line)
      
      -- Color based on hit count: green if > 0, red if 0
      local hl = (b.hits or 0) > 0 and config.covered_hl or config.uncovered_hl
      table.insert(hls, hl)
    end
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
  -- Get current cursor line
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
    zindex = cfg.zindex or 200,
    noautocmd = true,
    focusable = false,
  }

  local overlay_win = vim.api.nvim_open_win(overlay_buf, false, opts)
  local augroup_name = "CoverageBranchOverlay_" .. cur_win
  _branch_overlay.wins[cur_win] = { win = overlay_win, buf = overlay_buf, cursor_line = cursor_line, augroup = augroup_name }
  
  -- Auto-close overlay when cursor moves to a different line
  vim.api.nvim_create_augroup(augroup_name, { clear = true })
  vim.api.nvim_create_autocmd("CursorMoved", {
    group = augroup_name,
    buffer = buf,
    callback = function()
      local new_line = vim.api.nvim_win_get_cursor(cur_win)[1]
      if new_line ~= cursor_line then
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

return M
