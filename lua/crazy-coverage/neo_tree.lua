-- Neo-tree integration for coverage display
local M = {}

local config = require("crazy-coverage.config")
local utils = require("crazy-coverage.utils")


M.namespace = vim.api.nvim_create_namespace("crazy-coverage.neo-tree")

-- Highlight groups for neo-tree (foreground only, no background)
local _neo_tree_highlights_setup = false

local function setup_neo_tree_highlights()
  if _neo_tree_highlights_setup then
    return
  end
  _neo_tree_highlights_setup = true

  -- Create neo-tree specific highlight groups with fg only, less vibrant colors
  vim.api.nvim_set_hl(0, "CrazyCoverageNeoTreeCovered", { fg = "#77CC77", bold = true })
  vim.api.nvim_set_hl(0, "CrazyCoverageNeoTreeUncovered", { fg = "#CC7777", bold = true })
  vim.api.nvim_set_hl(0, "CrazyCoverageNeoTreePartial", { fg = "#DD9955", bold = true })
end

local function get_fill_symbol(percent)
  if percent >= 80 then
    return "█"
  elseif percent >= 60 then
    return "▆"
  elseif percent >= 40 then
    return "▄"
  elseif percent >= 20 then
    return "▂"
  else
    return "▁"
  end
end

local function pick_percent_hl(percent, thresholds)
  setup_neo_tree_highlights()
  local covered = (thresholds and thresholds.covered) or 80
  local partial = (thresholds and thresholds.partial) or 50
  if percent >= covered then
    return "CrazyCoverageNeoTreeCovered"
  elseif percent >= partial then
    return "CrazyCoverageNeoTreePartial"
  end
  return "CrazyCoverageNeoTreeUncovered"
end

local function compute_file_stats(file_entry)
  local total_lines = 0
  local covered_lines = 0
  local uncovered_lines = 0
  local partial_lines = 0

  local branch_map = {}
  for _, br in ipairs(file_entry.branches or {}) do
    local line_num = br.line_num or br.line
    if type(line_num) == "number" then
      if not branch_map[line_num] then
        branch_map[line_num] = { total = 0, taken = 0 }
      end
      branch_map[line_num].total = branch_map[line_num].total + 1
      local hit_count = br.hit_count
      if hit_count == nil then
        hit_count = br.hits
      end
      hit_count = hit_count or 0
      if hit_count > 0 then
        branch_map[line_num].taken = branch_map[line_num].taken + 1
      end
    end
  end

  for _, line_info in ipairs(file_entry.lines or {}) do
    local line_num = line_info.line_num or line_info.line
    if type(line_num) == "number" then
      total_lines = total_lines + 1
      local hit_count = line_info.hit_count
      if hit_count == nil then
        hit_count = line_info.hits
      end
      hit_count = hit_count or 0

      local branches = branch_map[line_num]
      if branches and branches.total > 0 then
        if branches.taken == 0 then
          uncovered_lines = uncovered_lines + 1
        elseif branches.taken > 0 and branches.taken < branches.total then
          partial_lines = partial_lines + 1
        else
          covered_lines = covered_lines + 1
        end
      else
        if hit_count > 0 then
          covered_lines = covered_lines + 1
        else
          uncovered_lines = uncovered_lines + 1
        end
      end
    end
  end

  if total_lines == 0 then
    for _, branches in pairs(branch_map) do
      total_lines = total_lines + 1
      if branches.taken == 0 then
        uncovered_lines = uncovered_lines + 1
      elseif branches.taken > 0 and branches.taken < branches.total then
        partial_lines = partial_lines + 1
      else
        covered_lines = covered_lines + 1
      end
    end
  end

  local percent = total_lines > 0 and (covered_lines / total_lines) * 100 or 0
  return {
    total_lines = total_lines,
    covered_lines = covered_lines,
    uncovered_lines = uncovered_lines,
    partial_lines = partial_lines,
    percent = percent,
  }
end

local function add_dir_stats(dir_stats, dir, stats)
  local acc = dir_stats[dir]
  if not acc then
    acc = {
      total_lines = 0,
      covered_lines = 0,
      uncovered_lines = 0,
      partial_lines = 0,
    }
  end
  acc.total_lines = acc.total_lines + (stats.total_lines or 0)
  acc.covered_lines = acc.covered_lines + (stats.covered_lines or 0)
  acc.uncovered_lines = acc.uncovered_lines + (stats.uncovered_lines or 0)
  acc.partial_lines = acc.partial_lines + (stats.partial_lines or 0)
  dir_stats[dir] = acc
end

local function build_stats_index(coverage_data, project_root)
  local file_stats = {}
  local dir_stats = {}

  for file_path, entry in pairs(coverage_data or {}) do
    local normalized = utils.normalize_path(file_path) or file_path
    local stats = compute_file_stats(entry)
    file_stats[normalized] = stats

    local dir = vim.fn.fnamemodify(normalized, ":h")
    while dir and dir ~= "" do
      if project_root and dir:sub(1, #project_root) ~= project_root then
        break
      end
      add_dir_stats(dir_stats, dir, stats)
      local parent = vim.fn.fnamemodify(dir, ":h")
      if parent == dir then
        break
      end
      dir = parent
    end
  end

  for _, acc in pairs(dir_stats) do
    acc.percent = acc.total_lines > 0 and (acc.covered_lines / acc.total_lines) * 100 or 0
  end

  return file_stats, dir_stats
end

local function node_is_dir(node)
  local node_type = node and node.type
  if node_type == "directory" or node_type == "dir" or node_type == "folder" then
    return true
  end
  if node and node.is_dir ~= nil then
    return node.is_dir
  end
  return false
end

local function node_path(node)
  if not node then
    return nil
  end
  local path = node.path or node.id
  if type(path) ~= "string" or path == "" then
    if type(node.get_id) == "function" then
      local ok, out = pcall(node.get_id, node)
      if ok then
        path = out
      end
    end
  end
  if type(path) ~= "string" or path == "" then
    return nil
  end
  return utils.normalize_path(path) or path
end

local function format_stats(stats, path, is_dir)
  local cfg = config.neo_tree or {}
  local formatter = cfg.format

  local fill_str = ""
  if cfg.fill_symbol then
    fill_str = get_fill_symbol(stats.percent or 0) .. " "
  end

  if type(formatter) == "function" then
    local ok, out = pcall(formatter, stats, path, is_dir)
    if ok then
      return fill_str .. out
    end
  elseif type(formatter) == "string" then
    if formatter == "percent" or formatter == "" then
      return fill_str .. string.format("%5.1f%%", stats.percent or 0)
    end
    return fill_str .. string.format(formatter, stats.percent or 0, stats.covered_lines or 0, stats.total_lines or 0)
  end

  return fill_str .. string.format("%5.1f%%", stats.percent or 0)
end

local function neo_tree_state_for_buf(buf)
  local source = vim.b[buf].neo_tree_source or vim.b[buf].neo_tree_source_name
  if type(source) ~= "string" or source == "" then
    source = "filesystem"
  end

  local ok_manager, manager = pcall(require, "neo-tree.sources.manager")
  if ok_manager and manager and type(manager.get_state) == "function" then
    return manager.get_state(source)
  end

  return nil
end

local function neo_tree_node_at_line(state, line)
  if not state then
    return nil
  end

  local ok_renderer, renderer = pcall(require, "neo-tree.ui.renderer")
  if ok_renderer and renderer and type(renderer.get_node_at_line) == "function" then
    local ok, node = pcall(renderer.get_node_at_line, state, line)
    if ok and node then
      return node
    end
  end

  local ok_common, common = pcall(require, "neo-tree.sources.common")
  if ok_common and common and type(common.get_node_at_line) == "function" then
    local ok, node = pcall(common.get_node_at_line, state, line)
    if ok and node then
      return node
    end
  end

  if state.tree and type(state.tree.get_node) == "function" then
    local ok, node = pcall(state.tree.get_node, state.tree, line)
    if ok and node then
      return node
    end
  end

  return nil
end

local function is_neo_tree_buffer(buf)
  return vim.bo[buf].filetype == "neo-tree"
end

-- Track which buffers we've attached to, to avoid duplicate attaches
local _attached_bufs = {}
-- Debounce timer per buffer to avoid redundant re-renders
local _debounce_timers = {}
-- Module-level events guard
local _events_ready = false

local function debounced_callback(callback, buf, delay_ms)
  delay_ms = delay_ms or 50
  if _debounce_timers[buf] then
    _debounce_timers[buf]:stop()
  end
  if not _debounce_timers[buf] then
    _debounce_timers[buf] = vim.loop.new_timer()
  end
  _debounce_timers[buf]:start(delay_ms, 0, vim.schedule_wrap(function()
    if vim.api.nvim_buf_is_valid(buf) and is_neo_tree_buffer(buf) then
      callback(buf)
    end
    if _debounce_timers[buf] then
      _debounce_timers[buf]:stop()
    end
  end))
end

local function attach_to_buf(callback, buf)
  if not buf or not vim.api.nvim_buf_is_valid(buf) then
    return
  end
  if not is_neo_tree_buffer(buf) then
    return
  end
  if _attached_bufs[buf] then
    return
  end
  _attached_bufs[buf] = true

  vim.api.nvim_buf_attach(buf, false, {
    on_lines = function(_, attached_buf)
      -- Neo-tree just modified buffer lines (toggle/expand/collapse)
      -- Defer re-render to let neo-tree finish its work
      debounced_callback(callback, attached_buf, 50)
    end,
    on_detach = function(_, attached_buf)
      _attached_bufs[attached_buf] = nil
      if _debounce_timers[attached_buf] then
        _debounce_timers[attached_buf]:stop()
        _debounce_timers[attached_buf] = nil
      end
    end,
  })
end

function M.render_buffer(buf, coverage_data, project_root)
  if not buf or not vim.api.nvim_buf_is_valid(buf) then
    return
  end

  vim.api.nvim_buf_call(buf, function()
    vim.api.nvim_buf_clear_namespace(buf, M.namespace, 0, -1)

    local cfg = config.neo_tree or {}
    if cfg.show_files == false and cfg.show_folders == false then
      return
    end

    local state = neo_tree_state_for_buf(buf)
    if not state then
      return
    end

    local file_stats, dir_stats = build_stats_index(coverage_data, project_root)
    local thresholds = cfg.thresholds or (config.summary and config.summary.thresholds)
    local line_count = vim.api.nvim_buf_line_count(buf)

    for line = 1, line_count do
      local node = neo_tree_node_at_line(state, line)
      if node then
        local path = node_path(node)
        if path then
          local is_dir = node_is_dir(node)
          if (is_dir and cfg.show_folders ~= false) or (not is_dir and cfg.show_files ~= false) then
            local stats = is_dir and dir_stats[path] or file_stats[path]
            if stats and (stats.total_lines or 0) > 0 then
              local text = format_stats(stats, path, is_dir)
              if text and text ~= "" then
                local hl = pick_percent_hl(stats.percent or 0, thresholds)
                local ok = pcall(vim.api.nvim_buf_set_extmark, buf, M.namespace, line - 1, 0, {
                  virt_text = { { text, hl } },
                  virt_text_pos = "right_align",
                  hl_mode = "combine",
                  priority = 200,
                })
                if not ok then
                  vim.notify("Failed to set neo-tree extmark on line " .. line, vim.log.levels.DEBUG)
                end
              end
            end
          end
        end
      end
    end
  end)
end

function M.render_all(coverage_data, project_root)
  for _, buf in ipairs(vim.api.nvim_list_bufs()) do
    if vim.api.nvim_buf_is_valid(buf) and is_neo_tree_buffer(buf) then
      M.render_buffer(buf, coverage_data, project_root)
    end
  end
end

function M.clear_buffer(buf)
  if not buf or not vim.api.nvim_buf_is_valid(buf) then
    return
  end
  vim.api.nvim_buf_clear_namespace(buf, M.namespace, 0, -1)
end

function M.clear_all()
  for _, buf in ipairs(vim.api.nvim_list_bufs()) do
    if vim.api.nvim_buf_is_valid(buf) and is_neo_tree_buffer(buf) then
      M.clear_buffer(buf)
    end
  end
end

function M.setup_events(callback)
  if _events_ready then
    return
  end
  _events_ready = true

  setup_neo_tree_highlights()

  -- Subscribe to neo-tree's own events
  local ok_events, events = pcall(require, "neo-tree.events")
  if ok_events and events and type(events.subscribe) == "function" then
    local event_list = {}
    if events.Event then
      table.insert(event_list, events.Event.NEO_TREE_RENDERER_RENDERED)
      table.insert(event_list, events.Event.NEO_TREE_RENDERED)
      table.insert(event_list, events.Event.NEO_TREE_BUFFER_ENTER)
      table.insert(event_list, events.Event.NEO_TREE_SOURCE_CHANGED)
    end

    for _, event in ipairs(event_list) do
      if event then
        pcall(events.subscribe, event, function(args)
          local buf = nil
          if type(args) == "table" then
            buf = args.bufnr or args.buf or args.buffer
          end
          if buf and vim.api.nvim_buf_is_valid(buf) then
            attach_to_buf(callback, buf)
            debounced_callback(callback, buf, 80)
          else
            -- Find all neo-tree buffers and refresh
            for _, b in ipairs(vim.api.nvim_list_bufs()) do
              if vim.api.nvim_buf_is_valid(b) and is_neo_tree_buffer(b) then
                attach_to_buf(callback, b)
                debounced_callback(callback, b, 80)
              end
            end
          end
        end)
      end
    end
  end

  -- Catch neo-tree buffer creation and entering
  vim.api.nvim_create_autocmd({ "FileType" }, {
    pattern = "neo-tree",
    callback = function(args)
      attach_to_buf(callback, args.buf)
      debounced_callback(callback, args.buf, 100)
    end,
  })

  vim.api.nvim_create_autocmd({ "BufEnter", "BufWinEnter", "WinEnter" }, {
    callback = function(args)
      local buf = args.buf
      if vim.api.nvim_buf_is_valid(buf) and is_neo_tree_buffer(buf) then
        attach_to_buf(callback, buf)
        debounced_callback(callback, buf, 50)
      end
    end,
  })

  -- Attach to any existing neo-tree buffers right now
  for _, buf in ipairs(vim.api.nvim_list_bufs()) do
    if vim.api.nvim_buf_is_valid(buf) and is_neo_tree_buffer(buf) then
      attach_to_buf(callback, buf)
    end
  end
end

return M
