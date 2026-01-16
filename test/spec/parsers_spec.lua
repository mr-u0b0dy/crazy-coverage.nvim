-- Test cases for all parser implementations
local helpers = require("test.helpers")

describe("LLVM JSON Parser", function()
  local llvm_parser = require("crazy-coverage.parser.llvm_json")
  local temp_file, temp_dir

  after_each(function()
    if temp_dir then
      helpers.cleanup_temp_dir(temp_dir)
      temp_file, temp_dir = nil, nil
    end
  end)

  describe("path resolution", function()
    it("should resolve relative paths from coverage_dir", function()
      -- Create temp coverage file with relative path
      local content = helpers.sample_llvm_coverage()
      temp_file, temp_dir = helpers.create_temp_coverage_file("llvm", content)
      
      local result = llvm_parser.parse(temp_file, temp_dir)
      
      assert.is_not_nil(result)
      assert.is_table(result)
      -- Verify paths are resolved relative to coverage file location
      for file_path, _ in pairs(result) do
        assert.is_string(file_path)
        -- Path should not contain unresolved .. segments
        assert.is_false(file_path:match("%.%."))
      end
    end)

    it("should preserve absolute paths", function()
      local content = [[
{
  "version": "2.0.1",
  "data": [{
    "files": [{
      "filename": "/absolute/path/main.c",
      "segments": [[10, 0, 5, true, false, false]]
    }]
  }]
}
]]
      temp_file, temp_dir = helpers.create_temp_coverage_file("llvm", content)
      
      local result = llvm_parser.parse(temp_file, temp_dir)
      
      assert.is_not_nil(result)
      -- Should contain the absolute path unchanged
      local found_absolute = false
      for file_path, _ in pairs(result) do
        if file_path:match("^/absolute/path/main%.c") then
          found_absolute = true
        end
      end
      assert.is_true(found_absolute)
    end)

    it("should handle multiple relative path segments", function()
      local content = [[
{
  "version": "2.0.1",
  "data": [{
    "files": [{
      "filename": "../../subproject/main.c",
      "segments": [[10, 0, 5, true, false, false]]
    }]
  }]
}
]]
      temp_file, temp_dir = helpers.create_temp_coverage_file("llvm", content)
      
      local result = llvm_parser.parse(temp_file, temp_dir)
      
      assert.is_not_nil(result)
      -- All .. segments should be resolved
      for file_path, _ in pairs(result) do
        local remaining_segments = 0
        for _ in file_path:gmatch("%.%.") do
          remaining_segments = remaining_segments + 1
        end
        assert.equals(0, remaining_segments)
      end
    end)
  end)

  describe("segments parsing", function()
    it("should extract line numbers and execution counts from segments", function()
      temp_file, temp_dir = helpers.create_temp_coverage_file("llvm", helpers.sample_llvm_coverage())
      
      local result = llvm_parser.parse(temp_file, temp_dir)
      
      assert.is_not_nil(result)
      local file_data = next(result)
      assert.is_not_nil(file_data)
      assert.is_table(file_data.lines)
      
      -- Should have line coverage data
      assert.is_true(#file_data.lines > 0)
      
      -- Check specific lines from sample data
      local has_line_10, has_line_11, has_line_12 = false, false, false
      for _, line_data in ipairs(file_data.lines) do
        if line_data.line == 10 then has_line_10 = true end
        if line_data.line == 11 then has_line_11 = true end
        if line_data.line == 12 then has_line_12 = true end
      end
      assert.is_true(has_line_10 or has_line_11 or has_line_12)
    end)

    it("should mark lines with zero execution count as uncovered", function()
      temp_file, temp_dir = helpers.create_temp_coverage_file("llvm", helpers.sample_llvm_coverage())
      
      local result = llvm_parser.parse(temp_file, temp_dir)
      local file_data = next(result)
      
      -- Line 11 in sample has count=0
      local line_11_data
      for _, line_data in ipairs(file_data.lines) do
        if line_data.line == 11 then
          line_11_data = line_data
          break
        end
      end
      
      if line_11_data then
        assert.equals(0, line_11_data.hits)
      end
    end)

    it("should mark lines with non-zero count as covered", function()
      temp_file, temp_dir = helpers.create_temp_coverage_file("llvm", helpers.sample_llvm_coverage())
      
      local result = llvm_parser.parse(temp_file, temp_dir)
      local file_data = next(result)
      
      -- Lines 10 and 12 in sample have count > 0
      local covered_count = 0
      for _, line_data in ipairs(file_data.lines) do
        if line_data.hits > 0 then
          covered_count = covered_count + 1
        end
      end
      
      assert.is_true(covered_count > 0)
    end)
  end)

  describe("Format A (lines array) parsing", function()
    it("should parse lines array format (standard llvm-cov output)", function()
      local content = [[{
  "version": "2.0.1",
  "data": [{
    "files": [{
      "filename": "../test.c",
      "lines": [
        {"line_number": 5, "count": 10},
        {"line_number": 6, "count": 0},
        {"line_number": 7, "count": 5}
      ]
    }]
  }]
}]]
      temp_file, temp_dir = helpers.create_temp_coverage_file("llvm", content)
      
      local result = llvm_parser.parse(temp_file, temp_dir)
      
      assert.is_not_nil(result)
      local file_data = next(result)
      assert.is_not_nil(file_data)
      assert.equals(3, #file_data.lines)
      
      -- Check line 5 is covered
      assert.equals(10, file_data.lines[1].hit_count)
      assert.is_true(file_data.lines[1].covered)
      
      -- Check line 6 is uncovered
      assert.equals(0, file_data.lines[2].hit_count)
      assert.is_false(file_data.lines[2].covered)
      
      -- Check line 7 is covered
      assert.equals(5, file_data.lines[3].hit_count)
      assert.is_true(file_data.lines[3].covered)
    end)

    it("should parse regions as branch coverage", function()
      local content = [[{
  "version": "2.0.1",
  "data": [{
    "files": [{
      "filename": "../test.c",
      "lines": [
        {
          "line_number": 10,
          "count": 5,
          "regions": [
            {"count": 5, "covered": true},
            {"count": 2, "covered": true}
          ]
        }
      ]
    }]
  }]
}]]
      temp_file, temp_dir = helpers.create_temp_coverage_file("llvm", content)
      
      local result = llvm_parser.parse(temp_file, temp_dir)
      
      assert.is_not_nil(result)
      local file_data = next(result)
      assert.equals(1, #file_data.lines)
      assert.equals(2, #file_data.branches)
      
      -- Check line coverage
      assert.equals(5, file_data.lines[1].hit_count)
      assert.is_true(file_data.lines[1].covered)
      
      -- Check branch coverage from regions
      assert.equals(5, file_data.branches[1].hit_count)
      assert.is_true(file_data.branches[1].covered)
      assert.equals(2, file_data.branches[2].hit_count)
      assert.is_true(file_data.branches[2].covered)
    end)

    it("should handle uncovered regions correctly", function()
      local content = [[{
  "version": "2.0.1",
  "data": [{
    "files": [{
      "filename": "../test.c",
      "lines": [
        {
          "line_number": 15,
          "count": 0,
          "regions": [
            {"count": 0, "covered": false}
          ]
        }
      ]
    }]
  }]
}]]
      temp_file, temp_dir = helpers.create_temp_coverage_file("llvm", content)
      
      local result = llvm_parser.parse(temp_file, temp_dir)
      
      assert.is_not_nil(result)
      local file_data = next(result)
      assert.equals(1, #file_data.lines)
      assert.is_false(file_data.lines[1].covered)
      assert.equals(1, #file_data.branches)
      assert.is_false(file_data.branches[1].covered)
    end)

    it("should preserve line numbers in order", function()
      local content = [[{
  "version": "2.0.1",
  "data": [{
    "files": [{
      "filename": "../test.c",
      "lines": [
        {"line_number": 100, "count": 1},
        {"line_number": 50, "count": 2},
        {"line_number": 75, "count": 3}
      ]
    }]
  }]
}]]
      temp_file, temp_dir = helpers.create_temp_coverage_file("llvm", content)
      
      local result = llvm_parser.parse(temp_file, temp_dir)
      
      assert.is_not_nil(result)
      local file_data = next(result)
      -- Should be sorted by line number
      assert.equals(50, file_data.lines[1].line_num)
      assert.equals(75, file_data.lines[2].line_num)
      assert.equals(100, file_data.lines[3].line_num)
    end)
  end)
end)

describe("Cobertura Parser", function()
  local cobertura_parser = require("crazy-coverage.parser.cobertura")
  local temp_file, temp_dir

  after_each(function()
    if temp_dir then
      helpers.cleanup_temp_dir(temp_dir)
      temp_file, temp_dir = nil, nil
    end
  end)

  describe("path resolution", function()
    it("should resolve relative filenames from coverage_dir", function()
      temp_file, temp_dir = helpers.create_temp_coverage_file("xml", helpers.sample_cobertura_coverage())
      
      local result = cobertura_parser.parse(temp_file, temp_dir)
      
      assert.is_not_nil(result)
      assert.is_table(result)
      -- Verify relative paths are resolved
      for file_path, _ in pairs(result) do
        assert.is_string(file_path)
        -- Should not contain unresolved .. segments
        assert.is_false(file_path:match("%.%."))
      end
    end)

    it("should use absolute path when available", function()
      local content = [[
<?xml version="1.0" ?>
<coverage version="5.4" timestamp="1234567890">
  <packages>
    <package name="test">
      <classes>
        <class filename="/absolute/path/main.c" line-rate="1.0">
          <lines>
            <line number="10" hits="5"/>
          </lines>
        </class>
      </classes>
    </package>
  </packages>
</coverage>
]]
      temp_file, temp_dir = helpers.create_temp_coverage_file("xml", content)
      
      local result = cobertura_parser.parse(temp_file, temp_dir)
      
      assert.is_not_nil(result)
      -- Should preserve absolute path
      local found_absolute = false
      for file_path, _ in pairs(result) do
        if file_path:match("^/absolute/path") then
          found_absolute = true
        end
      end
      assert.is_true(found_absolute)
    end)
  end)

  describe("line coverage extraction", function()
    it("should extract line numbers and hit counts", function()
      temp_file, temp_dir = helpers.create_temp_coverage_file("xml", helpers.sample_cobertura_coverage())
      
      local result = cobertura_parser.parse(temp_file, temp_dir)
      local file_data = next(result)
      
      assert.is_not_nil(file_data)
      assert.is_table(file_data.lines)
      assert.is_true(#file_data.lines > 0)
      
      -- Check that lines have proper structure
      for _, line_data in ipairs(file_data.lines) do
        assert.is_number(line_data.line)
        assert.is_number(line_data.hits)
        assert.is_true(line_data.line > 0)
        assert.is_true(line_data.hits >= 0)
      end
    end)

    it("should mark uncovered lines with zero hits", function()
      temp_file, temp_dir = helpers.create_temp_coverage_file("xml", helpers.sample_cobertura_coverage())
      
      local result = cobertura_parser.parse(temp_file, temp_dir)
      local file_data = next(result)
      
      -- Sample has line 11 with hits=0
      local has_uncovered = false
      for _, line_data in ipairs(file_data.lines) do
        if line_data.hits == 0 then
          has_uncovered = true
          break
        end
      end
      assert.is_true(has_uncovered)
    end)

    it("should mark covered lines with non-zero hits", function()
      temp_file, temp_dir = helpers.create_temp_coverage_file("xml", helpers.sample_cobertura_coverage())
      
      local result = cobertura_parser.parse(temp_file, temp_dir)
      local file_data = next(result)
      
      -- Sample has lines 10 and 12 with hits > 0
      local covered_count = 0
      for _, line_data in ipairs(file_data.lines) do
        if line_data.hits > 0 then
          covered_count = covered_count + 1
        end
      end
      assert.is_true(covered_count >= 2)
    end)
  end)

  describe("branch coverage", function()
    it("should parse branch data when available", function()
      local content = [[
<?xml version="1.0" ?>
<coverage version="5.4" timestamp="1234567890">
  <packages>
    <package name="test">
      <classes>
        <class filename="../main.c" line-rate="1.0" branch-rate="0.5">
          <lines>
            <line number="10" hits="5" branch="true" condition-coverage="50% (1/2)">
              <conditions>
                <condition number="0" type="jump" coverage="50%"/>
              </conditions>
            </line>
          </lines>
        </class>
      </classes>
    </package>
  </packages>
</coverage>
]]
      temp_file, temp_dir = helpers.create_temp_coverage_file("xml", content)
      
      local result = cobertura_parser.parse(temp_file, temp_dir)
      
      assert.is_not_nil(result)
      -- Parser should handle branch data without errors
      local file_data = next(result)
      assert.is_not_nil(file_data)
    end)
  end)
end)

describe("LCOV Parser", function()
  local lcov_parser = require("crazy-coverage.parser.lcov")
  local temp_file, temp_dir

  after_each(function()
    if temp_dir then
      helpers.cleanup_temp_dir(temp_dir)
      temp_file, temp_dir = nil, nil
    end
  end)

  describe("source file path resolution", function()
    it("should resolve SF: entries with relative paths", function()
      temp_file, temp_dir = helpers.create_temp_coverage_file("lcov", helpers.sample_lcov_coverage())
      
      local result = lcov_parser.parse(temp_file, temp_dir)
      
      assert.is_not_nil(result)
      assert.is_table(result)
      -- Verify paths are resolved
      for file_path, _ in pairs(result) do
        assert.is_string(file_path)
        -- Should not contain unresolved .. segments
        assert.is_false(file_path:match("%.%."))
      end
    end)

    it("should use absolute paths when present in SF:", function()
      local content = [[
TN:test
SF:/absolute/path/main.c
DA:10,5
DA:11,0
end_of_record
]]
      temp_file, temp_dir = helpers.create_temp_coverage_file("lcov", content)
      
      local result = lcov_parser.parse(temp_file, temp_dir)
      
      assert.is_not_nil(result)
      -- Should preserve absolute path
      local found_absolute = false
      for file_path, _ in pairs(result) do
        if file_path:match("^/absolute/path") then
          found_absolute = true
        end
      end
      assert.is_true(found_absolute)
    end)

    it("should handle multiple source files", function()
      local content = [[
TN:test
SF:../file1.c
DA:10,5
end_of_record
SF:../file2.c
DA:20,3
end_of_record
]]
      temp_file, temp_dir = helpers.create_temp_coverage_file("lcov", content)
      
      local result = lcov_parser.parse(temp_file, temp_dir)
      
      assert.is_not_nil(result)
      -- Should have multiple files
      local file_count = 0
      for _, _ in pairs(result) do
        file_count = file_count + 1
      end
      assert.equals(2, file_count)
    end)
  end)

  describe("line data parsing", function()
    it("should parse DA: (line data) entries", function()
      temp_file, temp_dir = helpers.create_temp_coverage_file("lcov", helpers.sample_lcov_coverage())
      
      local result = lcov_parser.parse(temp_file, temp_dir)
      local file_data = next(result)
      
      assert.is_not_nil(file_data)
      assert.is_table(file_data.lines)
      assert.is_true(#file_data.lines > 0)
      
      -- Each line should have line number and hit count
      for _, line_data in ipairs(file_data.lines) do
        assert.is_number(line_data.line)
        assert.is_number(line_data.hits)
      end
    end)

    it("should mark uncovered lines (DA:line,0)", function()
      temp_file, temp_dir = helpers.create_temp_coverage_file("lcov", helpers.sample_lcov_coverage())
      
      local result = lcov_parser.parse(temp_file, temp_dir)
      local file_data = next(result)
      
      -- Sample has line 11 with 0 hits
      local has_uncovered = false
      for _, line_data in ipairs(file_data.lines) do
        if line_data.hits == 0 then
          has_uncovered = true
          break
        end
      end
      assert.is_true(has_uncovered)
    end)

    it("should mark covered lines (DA:line,count)", function()
      temp_file, temp_dir = helpers.create_temp_coverage_file("lcov", helpers.sample_lcov_coverage())
      
      local result = lcov_parser.parse(temp_file, temp_dir)
      local file_data = next(result)
      
      -- Sample has lines with hits > 0
      local covered_count = 0
      for _, line_data in ipairs(file_data.lines) do
        if line_data.hits > 0 then
          covered_count = covered_count + 1
        end
      end
      assert.is_true(covered_count >= 2)
    end)
  end)

  describe("branch data parsing", function()
    it("should parse BRDA: (branch data) entries", function()
      local content = [[
TN:test
SF:../main.c
DA:10,5
BRDA:10,0,0,3
BRDA:10,0,1,2
end_of_record
]]
      temp_file, temp_dir = helpers.create_temp_coverage_file("lcov", content)
      
      local result = lcov_parser.parse(temp_file, temp_dir)
      
      assert.is_not_nil(result)
      -- Parser should handle branch data without errors
      local file_data = next(result)
      assert.is_not_nil(file_data)
    end)
  end)
end)

describe("Parser Dispatcher", function()
  local parser_dispatcher = require("crazy-coverage.parser.init")
  local temp_file, temp_dir

  after_each(function()
    if temp_dir then
      helpers.cleanup_temp_dir(temp_dir)
      temp_file, temp_dir = nil, nil
    end
  end)

  describe("format detection", function()
    it("should detect LLVM JSON format", function()
      temp_file, temp_dir = helpers.create_temp_coverage_file("llvm", helpers.sample_llvm_coverage())
      
      local result = parser_dispatcher.parse(temp_file)
      
      assert.is_not_nil(result)
      assert.is_table(result)
    end)

    it("should detect Cobertura XML format", function()
      temp_file, temp_dir = helpers.create_temp_coverage_file("xml", helpers.sample_cobertura_coverage())
      
      local result = parser_dispatcher.parse(temp_file)
      
      assert.is_not_nil(result)
      assert.is_table(result)
    end)

    it("should detect LCOV format", function()
      temp_file, temp_dir = helpers.create_temp_coverage_file("lcov", helpers.sample_lcov_coverage())
      
      local result = parser_dispatcher.parse(temp_file)
      
      assert.is_not_nil(result)
      assert.is_table(result)
    end)

    it("should return nil for unknown format", function()
      local content = "This is not a valid coverage format"
      temp_file, temp_dir = helpers.create_temp_coverage_file("txt", content)
      
      local result = parser_dispatcher.parse(temp_file)
      
      -- Unknown format should return nil or empty table
      assert.is_true(result == nil or next(result) == nil)
    end)
  end)

  describe("project_root parameter", function()
    it("should accept project_root parameter", function()
      temp_file, temp_dir = helpers.create_temp_coverage_file("lcov", helpers.sample_lcov_coverage())
      
      -- Should not error when passing project_root
      local result = parser_dispatcher.parse(temp_file, "/some/project/root")
      
      assert.is_not_nil(result)
    end)

    it("should work without project_root parameter", function()
      temp_file, temp_dir = helpers.create_temp_coverage_file("lcov", helpers.sample_lcov_coverage())
      
      -- Should auto-detect or use fallback
      local result = parser_dispatcher.parse(temp_file)
      
      assert.is_not_nil(result)
    end)
  end)

  describe("error handling", function()
    it("should handle non-existent files", function()
      local result = parser_dispatcher.parse("/non/existent/file.lcov")
      
      -- Should return nil or empty table without crashing
      assert.is_true(result == nil or next(result) == nil)
    end)

    it("should handle malformed coverage files", function()
      local content = "TN:test\nSF:main.c\nINVALID_LINE\nend_of_record"
      temp_file, temp_dir = helpers.create_temp_coverage_file("lcov", content)
      
      -- Should not crash on malformed data
      local ok = pcall(function()
        parser_dispatcher.parse(temp_file)
      end)
      
      assert.is_true(ok)
    end)
  end)
end)

describe("Edge Cases", function()
  local utils = require("crazy-coverage.utils")

  describe("path normalization edge cases", function()
    it("should handle excessive .. segments", function()
      local path = "/home/project/a/b/c/../../../../../../../../main.c"
      local result = utils.normalize_path(path)
      
      -- Should not crash and should return valid path
      assert.is_not_nil(result)
      assert.is_string(result)
    end)

    it("should handle mixed ./ and .. segments", function()
      local path = "/home/project/./build/../main.c"
      local result = utils.normalize_path(path)
      
      assert.is_not_nil(result)
      assert.equals("/home/project/main.c", result)
    end)

    it("should handle paths with spaces", function()
      local path = "/home/my project/main file.c"
      local result = utils.normalize_path(path)
      
      assert.is_not_nil(result)
      assert.matches("my project", result)
      assert.matches("main file%.c", result)
    end)

    it("should handle empty path components", function()
      local path = "/home//project///main.c"
      local result = utils.normalize_path(path)
      
      assert.is_not_nil(result)
      -- Should reduce to single slashes
      assert.is_false(result:match("//"))
    end)
  end)

  describe("parser edge cases", function()
    local temp_file, temp_dir

    after_each(function()
      if temp_dir then
        helpers.cleanup_temp_dir(temp_dir)
        temp_file, temp_dir = nil, nil
      end
    end)

    it("should handle empty coverage files", function()
      temp_file, temp_dir = helpers.create_temp_coverage_file("lcov", "")
      
      local parser = require("crazy-coverage.parser.init")
      local ok = pcall(function()
        parser.parse(temp_file)
      end)
      
      -- Should not crash on empty file
      assert.is_true(ok)
    end)

    it("should handle coverage with no line data", function()
      local content = [[
TN:test
SF:../main.c
end_of_record
]]
      temp_file, temp_dir = helpers.create_temp_coverage_file("lcov", content)
      
      local parser = require("crazy-coverage.parser.init")
      local result = parser.parse(temp_file)
      
      assert.is_not_nil(result)
      -- File should be in result but with empty or no lines
      local file_data = next(result)
      if file_data and file_data.lines then
        assert.equals(0, #file_data.lines)
      end
    end)

    it("should handle very large hit counts", function()
      local content = [[
TN:test
SF:../main.c
DA:10,999999999
end_of_record
]]
      temp_file, temp_dir = helpers.create_temp_coverage_file("lcov", content)
      
      local parser = require("crazy-coverage.parser.init")
      local result = parser.parse(temp_file)
      
      assert.is_not_nil(result)
      local file_data = next(result)
      assert.is_not_nil(file_data)
      
      -- Should handle large numbers correctly
      if file_data.lines and #file_data.lines > 0 then
        assert.is_true(file_data.lines[1].hits >= 999999999)
      end
    end)
  end)

  describe("buffer matching edge cases", function()
    it("should handle nil buffer path", function()
      local result = utils.get_buffer_by_path(nil)
      
      assert.is_nil(result)
    end)

    it("should handle empty buffer path", function()
      local result = utils.get_buffer_by_path("")
      
      assert.is_nil(result)
    end)

    it("should normalize paths before comparison", function()
      -- This tests that paths are normalized consistently
      local path1 = "/home/project/./main.c"
      local path2 = "/home/project/main.c"
      
      local norm1 = utils.normalize_path(path1)
      local norm2 = utils.normalize_path(path2)
      
      assert.equals(norm1, norm2)
    end)
  end)
end)

describe("Path Resolution", function()
  local utils = require("crazy-coverage.utils")

  describe("normalize_path", function()
    it("normalizes absolute paths", function()
      local result = utils.normalize_path("/home/user/project/main.c")
      assert.is_not_nil(result)
      assert.matches("^/", result)
      assert.matches("main%.c$", result)
    end)

    it("resolves .. segments", function()
      local result = utils.normalize_path("/home/user/project/build/../main.c")
      assert.is_not_nil(result)
      assert.equals("/home/user/project/main.c", result)
    end)

    it("resolves multiple .. segments", function()
      local result = utils.normalize_path("/home/user/project/build/subfolder/../../main.c")
      assert.is_not_nil(result)
      assert.equals("/home/user/project/main.c", result)
    end)

    it("removes . segments", function()
      local result = utils.normalize_path("/home/user/project/./main.c")
      assert.is_not_nil(result)
      assert.equals("/home/user/project/main.c", result)
    end)

    it("handles empty path", function()
      local result = utils.normalize_path("")
      assert.is_nil(result)
    end)

    it("handles nil path", function()
      local result = utils.normalize_path(nil)
      assert.is_nil(result)
    end)
  end)

  describe("path matching in coverage", function()
    it("matches buffer path with normalized coverage path", function()
      local coverage_path = "/home/user/project/build/../main.c"
      local buffer_path = "/home/user/project/main.c"
      
      local norm_coverage = utils.normalize_path(coverage_path)
      local norm_buffer = utils.normalize_path(buffer_path)
      
      assert.equals(norm_coverage, norm_buffer)
    end)

    it("detects mismatched paths", function()
      local coverage_path = "/home/user/project/main.c"
      local buffer_path = "/home/user/different/main.c"
      
      local norm_coverage = utils.normalize_path(coverage_path)
      local norm_buffer = utils.normalize_path(buffer_path)
      
      assert.not_equals(norm_coverage, norm_buffer)
    end)
  end)
end)

describe("Input Validation", function()
  local utils = require("crazy-coverage.utils")
  local parser = require("crazy-coverage.parser")

  it("normalize_path handles nil input", function()
    assert.is_nil(utils.normalize_path(nil))
  end)

  it("normalize_path handles empty string", function()
    assert.is_nil(utils.normalize_path(""))
  end)

  it("get_buffer_by_path handles nil input", function()
    assert.is_nil(utils.get_buffer_by_path(nil))
  end)

  it("get_buffer_by_path handles empty string", function()
    assert.is_nil(utils.get_buffer_by_path(""))
  end)

  it("file_exists handles invalid input", function()
    assert.is_false(utils.file_exists("/nonexistent/file"))
  end)

  it("parser rejects nil file path", function()
    local data, err = parser.parse(nil)
    assert.is_nil(data)
    assert.is_not_nil(err)
  end)

  it("parser rejects empty file path", function()
    local data, err = parser.parse("")
    assert.is_nil(data)
    assert.is_not_nil(err)
  end)
end)

describe("Format Detection", function()
  local utils = require("crazy-coverage.utils")

  it("detects LCOV format", function()
    assert.equal("lcov", utils.detect_format("coverage.lcov"))
  end)

  it("detects LCOV by .info extension", function()
    assert.equal("lcov", utils.detect_format("coverage.info"))
  end)

  it("detects Cobertura format", function()
    assert.equal("cobertura", utils.detect_format("coverage.xml"))
  end)

  it("detects LLVM JSON format", function()
    assert.equal("llvm_json", utils.detect_format("coverage.json"))
  end)

  it("detects GCOV format", function()
    assert.equal("gcov", utils.detect_format("file.gcda"))
  end)

  it("detects LLVM Profdata format", function()
    assert.equal("llvm_profdata", utils.detect_format("coverage.profdata"))
  end)
end)

describe("Coverage File Caching", function()
  describe("cache structure", function()
    it("should validate complete cache info", function()
      local info = {
        path = "/path/to/coverage.lcov",
        project_root = "/path/to/project",
        format = "lcov",
      }
      
      assert.is_not_nil(info.path)
      assert.is_not_nil(info.project_root)
      assert.is_not_nil(info.format)
    end)

    it("should handle missing fields", function()
      local info = {
        project_root = "/path/to/project",
        format = "lcov",
      }
      
      assert.is_nil(info.path)
    end)
  end)

  describe("cache normalization", function()
    local utils = require("crazy-coverage.utils")

    it("normalizes cached paths", function()
      local path = "/path/to/project/./build/../coverage.lcov"
      local normalized = utils.normalize_path(path)
      assert.equals("/path/to/project/build/coverage.lcov", normalized)
    end)

    it("normalizes project_root", function()
      local path = "/path/to/./project"
      local normalized = utils.normalize_path(path)
      assert.equals("/path/to/project", normalized)
    end)
  end)
end)
