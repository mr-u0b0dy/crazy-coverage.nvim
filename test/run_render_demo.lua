-- Headless renderer demo: create a buffer for src/math.c,
-- load coverage from test/fixtures/sample_coverage.lcov, render extmarks,
-- and print a short summary of virtual text per covered line.

-- Usage:
--   nvim --headless -u NONE +"lua dofile('test/run_render_demo.lua')" +qa

local cwd = vim.fn.getcwd()
package.path = package.path .. ';' .. cwd .. '/lua/?.lua;' .. cwd .. '/lua/?/init.lua;' .. cwd .. '/lua/?/?.lua'

local coverage = require('crazy-coverage')
local renderer = require('crazy-coverage.renderer')
local config = require('crazy-coverage.config')

coverage.setup({
  virt_text_pos = 'eol',
  show_hit_count = true,
  show_branch_summary = true,
  auto_load = false,
})

-- Create a scratch buffer and name it to match the coverage file path
local buf = vim.api.nvim_create_buf(false, true)
local file_abs = cwd .. '/src/math.c'
vim.api.nvim_buf_set_name(buf, file_abs)
vim.api.nvim_buf_set_option(buf, 'buftype', 'nofile')
vim.api.nvim_buf_set_option(buf, 'bufhidden', 'wipe')
vim.api.nvim_buf_set_option(buf, 'swapfile', false)

-- Populate the buffer with some placeholder content (20 lines)
local lines = {}
for i = 1, 20 do
  lines[i] = string.format('// line %d', i)
end
vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
vim.api.nvim_buf_set_option(buf, 'modified', false)

-- Load and render coverage
local sample = cwd .. '/test/fixtures/sample_coverage.lcov'
local ok = coverage.load_coverage(sample)
if not ok then
  print('Failed to load coverage: ' .. sample)
  return
end

-- Collect extmarks with details
local marks = vim.api.nvim_buf_get_extmarks(buf, renderer.namespace, 0, -1, { details = true })
print('Extmarks placed: ' .. tostring(#marks))
for _, m in ipairs(marks) do
  local id, row, col, details = m[1], m[2], m[3], m[4]
  local vt = details and details.virt_text or nil
  local vt_str = ''
  if vt then
    -- vt is array of {text, hl}
    local parts = {}
    for _, pair in ipairs(vt) do
      table.insert(parts, pair[1])
    end
    vt_str = table.concat(parts, '')
  end
  print(string.format('  line %d: %s', row + 1, vt_str))
end
