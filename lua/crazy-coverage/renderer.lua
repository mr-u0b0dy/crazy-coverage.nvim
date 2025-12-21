-- Renderer module - handles extmark rendering of coverage data
local M = {}
local config = require("crazy-coverage.config")
local utils = require("crazy-coverage.utils")

M.namespace = vim.api.nvim_create_namespace("coverage")

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
---@param coverage_data table -- CoverageData model
function M.render(coverage_data)
  if not coverage_data then
    error("coverage_data is required")
  end
  
  if not coverage_data.files or type(coverage_data.files) ~= "table" then
    error("coverage_data.files must be a table")
  end

  local rendered_count = 0
  for _, file_entry in ipairs(coverage_data.files) do
    if file_entry and file_entry.path then
      local buf = utils.get_buffer_by_path(file_entry.path)
      if buf then
        local ok, err = pcall(M.render_file, buf, file_entry)
        if ok then
          rendered_count = rendered_count + 1
        else
          vim.notify("Failed to render " .. file_entry.path .. ": " .. tostring(err), vim.log.levels.WARN)
        end
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
  
  if not file_entry.lines or type(file_entry.lines) ~= "table" then
    return -- No line data, skip silently
  end

  -- Clear previous marks for this buffer
  M.clear_buffer(buf)

  -- Create a map of line coverage for fast lookup
  local line_map = {}
  for _, line_info in ipairs(file_entry.lines) do
    line_map[line_info.line_num] = line_info
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

  -- Render each line
  for _, line_info in ipairs(file_entry.lines) do
    local line_num = line_info.line_num
    local hit_count = line_info.hit_count
    local covered = line_info.covered

    -- Determine highlight group
    local hl_group = covered and config.covered_hl or config.uncovered_hl

    -- Build virtual text
    local virt_text = {}
    if config.show_hit_count then
      table.insert(virt_text, { " " .. hit_count, hl_group })
    end

    if config.show_percentage and hit_count > 0 then
      table.insert(virt_text, { " (hit)", hl_group })
    end

    -- Optional branch summary: b:taken/total
    if config.show_branch_summary then
      local branches = branch_map[line_num]
      if branches and #branches > 0 then
        local total = #branches
        local taken = 0
        for _, br in ipairs(branches) do
          if (br.hit_count or 0) > 0 then
            taken = taken + 1
          end
        end
        local branch_hl
        if taken == 0 then
          branch_hl = config.uncovered_hl
        elseif taken == total then
          branch_hl = config.covered_hl
        else
          branch_hl = config.partial_hl
        end
        table.insert(virt_text, { " b:" .. taken .. "/" .. total, branch_hl })
      end
    end

    -- Place extmark on line
    if #virt_text > 0 then
      vim.api.nvim_buf_set_extmark(buf, M.namespace, line_num - 1, 0, {
        virt_text = virt_text,
        virt_text_pos = config.virt_text_pos,
        priority = 100,
        hl_eol = false,
      })
    end
  end
end

--- Set up highlight groups
function M.setup()
  config.setup_highlights()
end

return M
