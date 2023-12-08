-- Thin wrapper around 'nvim-web-devicons'
-- Created because the use of pcall creates problems when trying to mock or stub in tests

local devicons_installed, devicons = pcall(require, 'nvim-web-devicons')

return {
  ---@param filetype string
  ---@return string? icon
  ---@return string? highlight
  get_icon_by_filetype = function(filetype)
    if devicons_installed then
      local icon, highlight = devicons.get_icon_by_filetype(filetype)
      return icon, highlight
    end
    return nil, nil
  end,
}
