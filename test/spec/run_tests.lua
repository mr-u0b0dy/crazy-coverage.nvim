#!/usr/bin/env nvim
-- CI-ready test runner using plenary and busted
-- Usage: nvim --headless --noplugin -u NONE -c "luafile test/spec/run_tests.lua"

local function setup_package_path()
  local cwd = vim.fn.getcwd()
  package.path = package.path .. ';' .. cwd .. '/lua/?.lua;' .. cwd .. '/lua/?/init.lua;' .. cwd .. '/lua/?/?.lua'
end

setup_package_path()

-- Require plenary for testing
local busted = require("plenary.busted")

-- Run all spec files
describe("crazy-coverage.nvim test suite", function()
  require("test.spec.lcov_parser_spec")
  require("test.spec.json_parser_spec")
  require("test.spec.cobertura_parser_spec")
  require("test.spec.edge_cases_spec")
end)

-- Exit with success
vim.cmd("qa!")
