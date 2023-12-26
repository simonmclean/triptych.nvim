local u = require 'triptych.utils'

local M = {}

local this_dir = vim.fs.dirname(vim.api.nvim_buf_get_name(0))
local test_playground_dirname = 'test_playground'
M.test_playground_path = this_dir .. '/' .. test_playground_dirname

local function escape_double_quotes(str)
  return string.gsub(str, '"', '\\"')
end

local function create_file_or_dir(dir_path, file_or_dir)
  if file_or_dir.dir then
    local dir = file_or_dir
    local new_dir_path = dir_path .. '/' .. dir.dir
    vim.fn.system('mkdir ' .. new_dir_path)
    if u.is_defined(dir.children) then
      for i = 1, #dir.children, 1 do
        create_file_or_dir(new_dir_path, dir.children[i])
      end
    end
  else
    local file = file_or_dir
    local file_path = dir_path .. '/' .. file.file
    vim.fn.system('touch ' .. file_path)
    if u.is_defined(file.lines) then
      vim.fn.system('echo "' .. escape_double_quotes(file.lines) .. '" > ' .. file_path)
    end
  end
end

function M.cleanup()
  vim.fn.system('rm -rf ' .. M.test_playground_path)
end

M.js_lines = [[
const hello = "world"
console.log(1 + 1)
]]

M.java_lines = [[
class HelloWorld {
    public static void main(String[] args) {
        System.out.println("Hello, World!");
    }
}
]]

M.lua_lines = [[
local greeting = "hello world"
vim.print(greeting)
]]

function M.setup()
  local files_and_dirs = {
    dir = test_playground_dirname,
    children = {
      { file = 'level_1_file_1.js', lines = M.js_lines },
      { file = 'level_1_file_2.ts' },
      { file = 'level_1_file_3.lua' },
      {
        dir = 'level_1_dir_1',
        children = {
          { file = 'level_2_file_1.java', lines = M.java_lines },
          { file = 'level_2_file_2.sh' },
          { file = 'level_2_file_3.php' },
          {
            dir = 'level_2_dir_1',
            children = {
              { file = 'level_3_file_1.java', lines = M.java_lines },
              {
                dir = 'level_3_dir_1',
                children = {
                  {
                    dir = 'level_4_dir_1',
                    children = {
                      { file = 'level_5_file_1.lua', lines = M.lua_lines },
                    },
                  },
                  { file = 'level_4_file_1.js', lines = M.js_lines },
                },
              },
            },
          },
        },
      },
      { dir = 'level_1_dir_2', children = {} },
    },
  }
  create_file_or_dir(this_dir, files_and_dirs)
end

return M
