-- GUI renderer demo: Open actual source files from coverage-examples,
-- load their coverage files, and display coverage annotations.

-- Usage (GUI mode):
--   nvim +"lua dofile('test/run_render_demo.lua')"
-- Usage (headless mode - for testing):
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

-- Helper function to normalize paths
local function normalize_path(path)
  return vim.fn.fnamemodify(path, ':p'):gsub('/$', '')
end

-- Define coverage examples to load
local examples = {
  {
    name = 'C Example',
    coverage_file = cwd .. '/coverage-examples/c/build/coverage.lcov',
    source_files = {
      cwd .. '/coverage-examples/c/main.c',
      cwd .. '/coverage-examples/c/math_utils.c',
      cwd .. '/coverage-examples/c/math_utils.h',
    }
  },
  {
    name = 'C++ Example',
    coverage_file = cwd .. '/coverage-examples/cpp/build/coverage.lcov',
    source_files = {
      cwd .. '/coverage-examples/cpp/main.cpp',
      cwd .. '/coverage-examples/cpp/math_utils.cpp',
      cwd .. '/coverage-examples/cpp/math_utils.hpp',
    }
  },
}

-- Load and display each example (one file at a time with 5s delay)
for idx, example in ipairs(examples) do
  print('\n=== ' .. example.name .. ' ===')
  
  -- Load coverage
  local ok = coverage.load_coverage(example.coverage_file)
  if not ok then
    print('✗ Failed to load coverage: ' .. example.coverage_file)
  else
    print('✓ Loaded coverage: ' .. example.coverage_file)
    
    -- Get coverage data from plugin state
    local state = coverage.get_state()
    local coverage_data = state.coverage_data
    
    -- Open source files one at a time
    for _, filepath in ipairs(example.source_files) do
      -- Check if file exists
      if vim.fn.filereadable(filepath) == 1 then
        -- Open the file
        vim.cmd('edit ' .. vim.fn.fnameescape(filepath))
        print('✓ Opened: ' .. filepath)
        
        -- Get current buffer
        local buf = vim.api.nvim_get_current_buf()
        local buf_name = vim.api.nvim_buf_get_name(buf)
        
        -- Find matching file entry in coverage data
        local file_entry = nil
        if coverage_data and coverage_data.files then
          for _, entry in ipairs(coverage_data.files) do
            if entry.path == buf_name or entry.path == filepath then
              file_entry = entry
              break
            end
          end
        end
        
        -- Render coverage for this file
        if file_entry then
          renderer.render_file(buf, file_entry)
          print('  ✓ Coverage data applied')
        else
          print('  ⚠ No coverage data for this file')
        end
        
        -- Redraw to show the buffer
        vim.cmd('redraw')
        
        -- Get extmarks with details
        local marks = vim.api.nvim_buf_get_extmarks(buf, renderer.namespace, 0, -1, { details = true })
        print('  Coverage lines found: ' .. tostring(#marks))
        
        -- Print sample of coverage annotations
        if #marks > 0 then
          local sample_count = math.min(5, #marks)
          for i = 1, sample_count do
            local m = marks[i]
            local id, row, col, details = m[1], m[2], m[3], m[4]
            local vt = details and details.virt_text or nil
            if vt then
              local parts = {}
              for _, pair in ipairs(vt) do
                table.insert(parts, pair[1])
              end
              local vt_str = table.concat(parts, '')
              print(string.format('    line %d: %s', row + 1, vt_str))
            end
          end
          if #marks > sample_count then
            print(string.format('    ... and %d more lines', #marks - sample_count))
          end
        end
        
        -- Wait for 5 seconds
        vim.wait(5000, function() return false end)
        
        -- Close the buffer
        vim.cmd('bdelete')
        print('  Closed: ' .. filepath)
      else
        print('✗ File not found: ' .. filepath)
      end
    end
  end
end

print('\n=== Coverage Demo Complete ===')
print('All files have been displayed with coverage annotations.')
