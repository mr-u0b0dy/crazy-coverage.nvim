-- Headless parse demo for crazy-coverage.nvim
-- Run with: nvim --headless -u NONE -c "lua dofile('test/run_parse.lua') | qa"

-- Ensure plugin lua path is available
local cwd = vim.fn.getcwd()
package.path = package.path .. ';' .. cwd .. '/lua/?.lua;' .. cwd .. '/lua/?/init.lua;' .. cwd .. '/lua/?/?.lua'

local parser = require('crazy-coverage.parser')
local utils = require('crazy-coverage.utils')

local sample = cwd .. '/test/fixtures/sample_coverage.lcov'
local data, err = parser.parse(sample)

if not data then
  vim.notify('Parse failed: ' .. tostring(err), vim.log.levels.ERROR)
  return
end

-- Print a simple summary
local function summarize(coverage)
  local files = coverage.files or {}
  print('Files parsed: ' .. tostring(#files))
  for _, f in ipairs(files) do
    local covered = 0
    local total = #f.lines
    for _, ln in ipairs(f.lines) do
      if ln.covered then covered = covered + 1 end
    end
    print(string.format('  %s: %d/%d lines covered', f.path, covered, total))
    if f.functions and #f.functions > 0 then
      print('    functions:')
      for _, fn in ipairs(f.functions) do
        local name = fn.name or '<unknown>'
        local hits = fn.hit_count or 0
        local line = fn.line and tostring(fn.line) or '?' 
        print(string.format('      %s (line %s): %d hits', name, line, hits))
      end
    end
  end
end

summarize(data)
