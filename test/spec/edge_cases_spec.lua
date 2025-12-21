-- Edge case test suite: multi-file and empty coverage
local assert = require("luassert")
local parser = require("crazy-coverage.parser")

describe("Parser Edge Cases", function()
  describe("Multi-file LCOV", function()
    it("parses multiple files in one LCOV", function()
      local cwd = vim.fn.getcwd()
      local data = parser.parse(cwd .. "/test/fixtures/sample_coverage_multi.lcov")
      assert.is_not_nil(data)
      assert.equal(2, #data.files)
    end)

    it("tracks files independently", function()
      local cwd = vim.fn.getcwd()
      local data = parser.parse(cwd .. "/test/fixtures/sample_coverage_multi.lcov")
      
      local f1 = data.files[1]
      assert.equal("src/module_a.c", f1.path)
      assert.equal(4, #f1.lines)
      assert.equal(2, #f1.functions)
      
      local f2 = data.files[2]
      assert.equal("src/module_b.c", f2.path)
      assert.equal(2, #f2.lines)
      assert.equal(1, #f2.functions)
    end)

    it("handles functions across files", function()
      local cwd = vim.fn.getcwd()
      local data = parser.parse(cwd .. "/test/fixtures/sample_coverage_multi.lcov")
      
      local f1_fn1 = data.files[1].functions[1]
      assert.equal("func_a", f1_fn1.name)
      assert.equal(3, f1_fn1.hit_count)
      
      local f1_fn2 = data.files[1].functions[2]
      assert.equal("func_b", f1_fn2.name)
      assert.equal(0, f1_fn2.hit_count)
      assert.is_false(f1_fn2.covered)
    end)
  end)

  describe("Empty coverage", function()
    it("returns valid structure for empty LCOV", function()
      local cwd = vim.fn.getcwd()
      local data = parser.parse(cwd .. "/test/fixtures/sample_coverage_empty.lcov")
      assert.is_not_nil(data)
      assert.equal(0, #data.files)
    end)
  end)

  describe("Format auto-detection", function()
    it("detects LCOV by .info extension", function()
      local cwd = vim.fn.getcwd()
      local utils = require("crazy-coverage.utils")
      assert.equal("lcov", utils.detect_format(cwd .. "/test/fixtures/sample_coverage.lcov"))
    end)

    it("detects JSON by .json extension", function()
      local cwd = vim.fn.getcwd()
      local utils = require("crazy-coverage.utils")
      assert.equal("llvm_json", utils.detect_format(cwd .. "/test/fixtures/sample_coverage.json"))
    end)

    it("detects XML by .xml extension", function()
      local cwd = vim.fn.getcwd()
      local utils = require("crazy-coverage.utils")
      assert.equal("cobertura", utils.detect_format(cwd .. "/test/fixtures/sample_coverage.xml"))
    end)
  end)
end)
