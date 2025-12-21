-- LLVM JSON parser test suite using plenary
local assert = require("luassert")
local parser = require("crazy-coverage.parser")

describe("LLVM JSON Parser", function()
  it("parses sample LLVM JSON with lines and regions", function()
    local cwd = vim.fn.getcwd()
    local data = parser.parse(cwd .. "/test/fixtures/sample_coverage.json")
    assert.is_not_nil(data)
    assert.equal(1, #data.files)
    
    local f = data.files[1]
    assert.equal("src/math.cpp", f.path)
    assert.equal(5, #f.lines)
  end)

  it("converts regions to branch entries", function()
    local cwd = vim.fn.getcwd()
    local data = parser.parse(cwd .. "/test/fixtures/sample_coverage.json")
    local f = data.files[1]
    
    -- lines 10 and 15 have regions, each becomes a branch
    assert.equal(2, #f.branches)
  end)

  it("counts covered lines correctly", function()
    local cwd = vim.fn.getcwd()
    local data = parser.parse(cwd .. "/test/fixtures/sample_coverage.json")
    local f = data.files[1]
    
    local covered = 0
    for _, ln in ipairs(f.lines) do
      if ln.covered then covered = covered + 1 end
    end
    assert.equal(4, covered)
  end)

  it("parses hit counts from line count field", function()
    local cwd = vim.fn.getcwd()
    local data = parser.parse(cwd .. "/test/fixtures/sample_coverage.json")
    local f = data.files[1]
    
    -- Check first line (5, count=1)
    assert.equal(5, f.lines[1].line_num)
    assert.equal(1, f.lines[1].hit_count)
    assert.is_true(f.lines[1].covered)
  end)

  it("returns nil for invalid JSON", function()
    local data = parser.parse("/nonexistent/file.json")
    assert.is_nil(data)
  end)
end)
