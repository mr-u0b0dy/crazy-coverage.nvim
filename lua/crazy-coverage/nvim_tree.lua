-- NvimTree integration for coverage display
local M = {}

local config = require("crazy-coverage.config")
local utils = require("crazy-coverage.utils")

M.namespace = vim.api.nvim_create_namespace("crazy-coverage.nvim-tree")

-- Highlight groups for nvim-tree (foreground only, no background)
local _nvim_tree_highlights_setup = false

local function setup_nvim_tree_highlights()
  if _nvim_tree_highlights_setup then
    return
  end
  _nvim_tree_highlights_setup = true

  -- Create nvim-tree specific highlight groups with fg only, less vibrant colors
  vim.api.nvim_set_hl(0, "CrazyCoverageNvimTreeCovered", { fg = "#77CC77", bold = true })
  vim.api.nvim_set_hl(0, "CrazyCoverageNvimTreeUncovered", { fg = "#CC7777", bold = true })
  vim.api.nvim_set_hl(0, "CrazyCoverageNvimTreePartial", { fg = "#DD9955", bold = true })
end

local _events_ready = false

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
  setup_nvim_tree_highlights()
  local covered = (thresholds and thresholds.covered) or 80
  local partial = (thresholds and thresholds.partial) or 50
  if percent >= covered then
    return "CrazyCoverageNvimTreeCovered"
  elseif percent >= partial then
    return "CrazyCoverageNvimTreePartial"
  end
  return "CrazyCoverageNvimTreeUncovered"
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
  if node.type == "directory" then
    return true
  end
  if node.nodes ~= nil then
    return true
  end
  if node.open ~= nil and node.type ~= "file" then
    return true
  end
  return false
end

local function node_path(node)
  if not node then
    return nil
  end
  local path = node.absolute_path or node.path or node.link_to
  if type(path) ~= "string" or path == "" then
    return nil
  end
  return utils.normalize_path(path) or path
end

local function format_stats(stats, path, is_dir)
  local cfg = config.nvim_tree or {}
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

function M.render_buffer(buf, coverage_data, project_root)
  if not buf or not vim.api.nvim_buf_is_valid(buf) then
    return
  end

  vim.api.nvim_buf_call(buf, function()
    vim.api.nvim_buf_clear_namespace(buf, M.namespace, 0, -1)

    local cfg = config.nvim_tree or {}
    if cfg.show_files == false and cfg.show_folders == false then
      return
    end

    local ok_lib, lib = pcall(require, "nvim-tree.lib")
    if not ok_lib or type(lib.get_node_at_line) ~= "function" then
      return
    end

    local file_stats, dir_stats = build_stats_index(coverage_data, project_root)
    local thresholds = cfg.thresholds or (config.summary and config.summary.thresholds)
    local line_count = vim.api.nvim_buf_line_count(buf)

    for line = 1, line_count do
      local ok, node = pcall(lib.get_node_at_line, line)
      if ok and node then
        local path = node_path(node)
        if path then
          local is_dir = node_is_dir(node)
          if (is_dir and cfg.show_folders ~= false) or (not is_dir and cfg.show_files ~= false) then
            local stats = is_dir and dir_stats[path] or file_stats[path]
            if stats and (stats.total_lines or 0) > 0 then
              local text = format_stats(stats, path, is_dir)
              if text and text ~= "" then
                local hl = pick_percent_hl(stats.percent or 0, thresholds)
                local ok_mark = pcall(vim.api.nvim_buf_set_extmark, buf, M.namespace, line - 1, 0, {
                  virt_text = { { text, hl } },
                  virt_text_pos = "right_align",
                  hl_mode = "combine",
                  priority = 200,
                })
                if not ok_mark then
                  vim.notify("Failed to set nvim-tree extmark on line " .. line, vim.log.levels.DEBUG)
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
    if vim.api.nvim_buf_is_valid(buf) and vim.bo[buf].filetype == "NvimTree" then
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
    if vim.api.nvim_buf_is_valid(buf) and vim.bo[buf].filetype == "NvimTree" then
      M.clear_buffer(buf)
    end
  end
end

function M.setup_events(callback)
  if _events_ready then
    return
  end
  _events_ready = true

  local ok_api, api = pcall(require, "nvim-tree.api")
  if ok_api and api and api.events and api.events.subscribe then
    local event = (api.events.Event and api.events.Event.TreeRendered) or "TreeRendered"
    pcall(api.events.subscribe, event, function(data)
      local buf = nil
      if type(data) == "table" then
        buf = data.bufnr or data.buf
      end
      if not buf then
        local ok_view, view = pcall(require, "nvim-tree.view")
        if ok_view and view and type(view.get_bufnr) == "function" then
          buf = view.get_bufnr()
        end
      end
      if buf then
        callback(buf)
      end
    end)
  end

  vim.api.nvim_create_autocmd({ "FileType", "BufEnter", "BufWinEnter" }, {
    pattern = "NvimTree",
    callback = function(args)
      callback(args.buf)
    end,
  })
end

return M
