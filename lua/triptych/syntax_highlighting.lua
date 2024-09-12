local u = require 'triptych.utils'

local M = {}

---@param buf number
---@return nil
M.stop = function(buf)
  vim.treesitter.stop(buf)
  vim.api.nvim_buf_set_option(buf, 'syntax', 'off')
end

---@param buf number
---@param filetype? string
---@return nil
M.start = function(buf, filetype)
  -- Because this function will be debounced we need to check that the buffer still exists
  if not vim.api.nvim_buf_is_valid(buf) then
    return
  end

  if u.is_empty(filetype) then
    M.stop(buf)
    return
  end

  local treesitter_applied = false
  local lang = vim.treesitter.language.get_lang(filetype)
  if lang then
    local success, _ = pcall(vim.treesitter.get_parser, buf, lang)
    if success then
      vim.treesitter.start(buf, lang)
      treesitter_applied = true
    end
  end
  if not treesitter_applied then
    -- Fallback to regex syntax highlighting
    vim.api.nvim_buf_set_option(buf, 'syntax', filetype)
  end
end

return M
