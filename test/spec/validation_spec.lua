-- Validation tests for core functions
local assert = require("luassert")
local utils = require("crazy-coverage.utils")
local parser = require("crazy-coverage.parser")

describe("Input Validation", function()
  it("normalize_path handles nil input", function()
    assert.is_nil(utils.normalize_path(nil))
  end)

  it("normalize_path handles empty string", function()
    assert.is_nil(utils.normalize_path(""))
  end)

  it("get_buffer_by_path handles nil input", function()
    assert.is_nil(utils.get_buffer_by_path(nil))
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
  it("detects LCOV format", function()
    local fmt = utils.detect_format("coverage.lcov")
    assert.equal("lcov", fmt)
  end)

  it("detects Cobertura format", function()
    local fmt = utils.detect_format("coverage.xml")
    assert.equal("cobertura", fmt)
  end)

  it("detects GCOV format", function()
    local fmt = utils.detect_format("file.gcda")
    assert.equal("gcov", fmt)
  end)

  it("detects LLVM Profdata format", function()
    local fmt = utils.detect_format("coverage.profdata")
    assert.equal("llvm_profdata", fmt)
  end)

  it("returns nil for unknown format", function()
    local fmt = utils.detect_format("coverage.unknown")
    assert.is_nil(fmt)
  end)
end)
