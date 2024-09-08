local u = require 'tests.utils'
local uv = vim.loop

local function get_files_in_dir(dir)
  local files = {}
  local handle = uv.fs_scandir(dir)

  if handle then
    local name, type = uv.fs_scandir_next(handle)
    while name do
      local full_path = dir .. '/' .. name
      if type == 'file' then
        table.insert(files, full_path)
      elseif type == 'directory' then
        -- Recursively list subdirectories if needed
        local sub_files = get_files_in_dir(full_path)
        vim.list_extend(files, sub_files)
      end
      name, type = uv.fs_scandir_next(handle)
    end
  end

  return files
end

local function run_specs()
  vim.schedule(function()
    local cwd = vim.fn.getcwd()
    local spec_dir = cwd .. '/tests/specs'
    local specs = get_files_in_dir(spec_dir)
    for _, spec in ipairs(specs) do
      vim.cmd(':source ' .. spec)
    end
  end)
end

local is_headless = #vim.api.nvim_list_uis() == 0

if is_headless then
  vim.api.nvim_create_autocmd({ 'VimEnter' }, {
    callback = function()
      -- The "VeryLazy" event doesn't seem to run in headless mode, so we need to call setup() manually.
      -- Probably not a bad thing anyway, to use the default config for tests.
      require('triptych').setup()
      run_specs()
    end,
  })
else
  -- This allows to us to run specs by sourcing this file using :so%
  run_specs()
end
