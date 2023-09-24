--- @class FunctionCallLog
--- @field func_name string
--- @field args any ...

return function()
  ---@type FunctionCallLog[]
  local call_log = {}

  local function log_function_call(func_name, args)
    table.insert(call_log, {
      func_name = func_name,
      args = args,
    })
  end

  local mock_vim = {
    g = {
      tryptic_config = {},
    },

    o = {
      lines = 30,
      columns = 50,
    },

    keymap = {
      set = function(mode, k, fn, opts)
        log_function_call('keymap.set', { mode, k, fn, opts })
      end,
    },

    cmd = {
      read = function(path)
        log_function_call('cmd.read', path)
      end,
    },

    diagnostic = {
      get = function()
        return {}
      end,
    },

    --- The fs functions use the actual implementations
    fs = {
      dirname = function(path)
        log_function_call('fs.dirname', path)
        return vim.fs.dirname(path)
      end,

      basename = function(path)
        log_function_call('fs.basename', path)
        return vim.fs.basename(path)
      end,

      normalize = function(path)
        log_function_call('fs.normalize', path)
        return vim.fs.normalize(path)
      end,

      parents = function(path)
        log_function_call(path)
        return vim.fs.parents(path)
      end,

      dir = function(path)
        log_function_call('fs.dir', path)
        return vim.fs.dir(path)
      end,
    },

    --- The fn functions use the actual implementations
    fn = {
      isdirectory = function(path)
        log_function_call('fn.isdirectory', path)
        return vim.fn.isdirectory(path)
      end,

      system = function(cmd)
        log_function_call('fn.system', cmd)
        return ''
      end,

      getcwd = function()
        log_function_call 'fn.getcwd'
        return vim.fn.getcwd()
      end,

      getfsize = function(path)
        log_function_call('fn.getfsize', path)
        return vim.fn.getfsize(path)
      end,

      sign_unplace = function(group)
        log_function_call('fn.sign_unplace', group)
        return nil
      end,

      sign_getdefined = function(sign_name)
        log_function_call('fn.sign_getdefined', sign_name)
        return {}
      end,

      sign_place = function(id, group, name, buf, dict)
        log_function_call('fn.sign_place', { id, group, name, buf, dict })
      end,
    },

    api = {
      nvim_create_autocmd = function(name, config)
        log_function_call('name', { name, config })
      end,

      nvim_exec2 = function(vimscript, options)
        log_function_call('nvim_exec2', { vimscript, options })
      end,

      nvim_buf_get_name = function(bufnr)
        log_function_call('nvim_buf_get_name', bufnr)
        return '/Users/bob/code/tryptic/test_file.lua'
      end,

      -- TODO: Return value
      nvim_buf_get_lines = function(bufnr, from, to, strict_indexing)
        log_function_call('nvim_buf_get_lines', { bufnr, from, to, strict_indexing })
        return {}
      end,

      nvim_buf_delete = function(bufnr, options)
        log_function_call('nvim_buf_delete', { bufnr, options })
      end,

      nvim_get_current_win = function()
        log_function_call 'nvim_get_current_win'
      end,

      nvim_set_current_win = function(win_id)
        log_function_call('nvim_set_current_win', win_id)
      end,

      --- TODO: Return win 1,2, or 3
      nvim_open_win = function(bufnr, enter, config)
        log_function_call('nvim_open_win', { bufnr, enter, config })
        return 1
      end,

      nvim_win_set_option = function(winid, option, value)
        log_function_call('nvim_win_set_option', { winid, option, value })
      end,

      -- TODO: Return 1, 2 or 3
      nvim_win_get_buf = function(winid)
        log_function_call('nvim_win_get_buf', winid)
        return 1
      end,

      nvim_win_set_cursor = function(winid, config)
        log_function_call('nvim_win_set_cursor', { winid, config })
        return nil
      end,

      nvim_win_call = function(winid, fn)
        log_function_call('nvim_win_call', { winid, fn })
      end,

      nvim_buf_call = function(bufnr, fn)
        log_function_call('nvim_buf_call', { bufnr, fn })
      end,

      --- TODO: This will need to return something like 1, 2 and 3
      nvim_create_buf = function(listed, scratch)
        log_function_call('nvim_create_buf', { listed, scratch })
        return 1
      end,

      nvim_buf_set_option = function(bufnr, option, value)
        log_function_call('nvim_buf_set_option', { bufnr, option, value })
      end,

      nvim_buf_line_count = function(bufnr)
        log_function_call('nvim_buf_line_count', bufnr)
        return 1
      end,

      nvim_buf_set_lines = function(bufnr, from, to, strict_indexing, lines)
        log_function_call('nvim_buf_set_lines', { bufnr, from, to, strict_indexing, lines })
      end,

      nvim_buf_add_highlight = function(bufnr, nsid, hlgroup, line, colstart, colend)
        log_function_call('nvim_buf_add_highlight', { bufnr, nsid, hlgroup, line, colstart, colend })
      end,
    },
  }

  return mock_vim, call_log
end
