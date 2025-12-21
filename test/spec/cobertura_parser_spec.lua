-- Cobertura XML parser test suite using plenary
local assert = require("luassert")
local parser = require("crazy-coverage.parser")

describe("Cobertura XML Parser", function()
  it("parses sample Cobertura XML with self-closing line tags", function()
    local cwd = vim.fn.getcwd()
    local data = parser.parse(cwd .. "/test/fixtures/sample_coverage.xml")
    assert.is_not_nil(data)
    assert.equal(1, #data.files)
    
    local f = data.files[1]
    assert.equal("src/math.c", f.path)
    assert.equal(6, #f.lines)
  end)

  it("counts covered lines correctly", function()
    local cwd = vim.fn.getcwd()
    local data = parser.parse(cwd .. "/test/fixtures/sample_coverage.xml")
    local f = data.files[1]
    
    local covered = 0
    for _, ln in ipairs(f.lines) do
      if ln.covered then covered = covered + 1 end
    end
    assert.equal(4, covered)
  end)

  it("parses hit counts from hits attribute", function()
    local cwd = vim.fn.getcwd()
    local data = parser.parse(cwd .. "/test/fixtures/sample_coverage.xml")
    local f = data.files[1]
    
    -- First line (5, hits=1)
    assert.equal(5, f.lines[1].line_num)
    assert.equal(1, f.lines[1].hit_count)
    assert.is_true(f.lines[1].covered)
    
    -- Uncovered line (15, hits=0)
    assert.equal(15, f.lines[5].line_num)
    assert.equal(0, f.lines[5].hit_count)
    assert.is_false(f.lines[5].covered)
  end)

  it("returns nil for non-existent file", function()
    local data = parser.parse("/nonexistent/file.xml")
    assert.is_nil(data)
  end)
end)
