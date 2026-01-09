-- Test helpers and utilities
local M = {}

-- Create temporary coverage files for testing
function M.create_temp_coverage_file(format, content)
  local tmp_dir = "/tmp/crazy-coverage-test-" .. os.time()
  os.execute("mkdir -p " .. tmp_dir)
  
  local ext = format == "llvm" and "json" or format
  local filename = tmp_dir .. "/coverage." .. ext
  local file = io.open(filename, "w")
  if file then
    file:write(content)
    file:close()
    return filename, tmp_dir
  end
  return nil
end

-- Clean up temporary directories
function M.cleanup_temp_dir(path)
  if path then
    os.execute("rm -rf " .. path)
  end
end

-- Create mock vim buffer for testing
function M.create_mock_buffer(path, content)
  return {
    path = path,
    content = content,
    lines = vim.split(content, "\n"),
  }
end

-- Sample coverage data generators
function M.sample_llvm_coverage()
  return [[{
  "version": "2.0.1",
  "data": [{
    "files": [{
      "filename": "../main.c",
      "segments": [[10, 0, 5, true, false, false], [11, 0, 0, true, false, false], [12, 0, 3, true, false, false]]
    }]
  }]
}]]
end

function M.sample_cobertura_coverage()
  return [[<?xml version="1.0" ?>
<coverage version="5.4" timestamp="1234567890" lines-valid="3" lines-covered="2" line-rate="0.667">
  <packages>
    <package name="main" line-rate="0.667" branch-rate="1.0">
      <classes>
        <class filename="../main.c" line-rate="0.667" branch-rate="1.0">
          <methods/>
          <lines>
            <line number="10" hits="5"/>
            <line number="11" hits="0"/>
            <line number="12" hits="3"/>
          </lines>
        </class>
      </classes>
    </package>
  </packages>
</coverage>]]
end

function M.sample_lcov_coverage()
  return [[TN:main.c
SF:../main.c
DA:10,5
DA:11,0
DA:12,3
end_of_record
]]
end

return M
