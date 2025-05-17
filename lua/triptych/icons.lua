-- Thin wrapper around 'nvim-web-devicons'
-- Created because the use of pcall creates problems when trying to mock or stub in tests

local devicons_installed, devicons = pcall(require, 'nvim-web-devicons')

return {
  ---@param filename string?
  ---@return string? icon
  ---@return string? highlight
  get_icon_by_filename = function(filename)
    if devicons_installed and filename then
      -- Capture all characters after the last dot
      local file_ext = filename:match('^.*%.(.*)$')

      local icon, highlight = devicons.get_icon(filename, file_ext)
      return icon, highlight
    end
    return nil, nil
  end,
}
