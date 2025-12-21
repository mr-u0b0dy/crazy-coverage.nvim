local cwd = vim.fn.getcwd()
package.path = package.path .. ';' .. cwd .. '/lua/?.lua;' .. cwd .. '/lua/?/init.lua;' .. cwd .. '/lua/?/?.lua'

local cobre = require('crazy-coverage.parser.cobertura')
local utils = require('crazy-coverage.utils')
local fp = cwd .. '/test/fixtures/sample_coverage.xml'
print('file exists:', utils.file_exists(fp))
local data = cobre.parse(fp)
if not data then
  print('parse returned nil')
else
  print('files:', #data.files)
  for i, f in ipairs(data.files) do
    print('  file', i, f.path, '#lines', #f.lines)
  end
end
