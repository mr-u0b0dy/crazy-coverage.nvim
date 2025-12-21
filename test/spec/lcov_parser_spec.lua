-- LCOV parser test suite
local assert = require("luassert")
local parser = require("crazy-coverage.parser")

describe("LCOV Parser", function()
  local cwd = vim.fn.getcwd()
  local sample = cwd .. "/test/fixtures/sample_coverage.lcov"

  it("parses sample LCOV file", function()
    local data = parser.parse(sample)
    assert.is_not_nil(data)
    assert.equal(1, #data.files)
  end)

  it("extracts line coverage", function()
    local data = parser.parse(sample)
    local f = data.files[1]
    assert.equal("src/math.c", f.path)
    assert.equal(6, #f.lines)
  end)

  it("counts covered lines", function()
    local data = parser.parse(sample)
    local f = data.files[1]
    local covered = 0
    for _, ln in ipairs(f.lines) do
      if ln.covered then covered = covered + 1 end
    end
    assert.equal(4, covered)
  end)

  it("extracts function data", function()
    local data = parser.parse(sample)
    local f = data.files[1]
    assert.equal(1, #f.functions)
    assert.equal("add_numbers", f.functions[1].name)
    assert.equal(2, f.functions[1].hit_count)
  end)

  it("extracts branch data", function()
    local data = parser.parse(sample)
    local f = data.files[1]
    assert.equal(2, #f.branches)
  end)

  it("returns nil for invalid file", function()
    local data = parser.parse("/nonexistent/file.lcov")
    assert.is_nil(data)
  end)
end)
