local M = {}

-- Cache to store highlight groups so we don't recreate them unnecessarily
local hl_cache = {}

--- Get either the foreground (fg) or background (bg) color of a highlight group.
--- @param hl_name string
--- @param part ('fg' | 'bg')
--- @return string|nil - Hex color if found
local function get_hl_color(hl_name, part)
  local hl = vim.api.nvim_get_hl(0, { name = hl_name, link = false })
  -- Convert to hex strings
  if part == 'fg' then
    return hl.fg and string.format('#%06x', hl.fg)
  elseif part == 'bg' then
    return hl.bg and string.format('#%06x', hl.bg)
  end
end

--- Get or create a highlight group that combines the given foreground and background highlights
--- If the group has already been created, return it from the cache.
--- @param fg_hl string
--- @param bg_hl string
--- @return string
local function get_or_create_hl(fg_hl, bg_hl)
  local cache_key = 'TriptychFg' .. fg_hl .. 'Bg' .. bg_hl

  if hl_cache[cache_key] then
    return hl_cache[cache_key]
  end

  -- If not cached, extract the colours from highlight groups
  local fg_color = get_hl_color(fg_hl, 'fg')
  local bg_color = get_hl_color(bg_hl, 'bg')
  local hl_group = cache_key

  vim.api.nvim_set_hl(0, hl_group, { fg = fg_color, bg = bg_color })

  hl_cache[cache_key] = hl_group

  return hl_group
end

--- Creates a new highlight group that combines the given foreground and background (uses caching)
--- @param fg_hl string
--- @param bg_hl string
--- @param str string
--- @return string
M.with_highlight_groups = function(fg_hl, bg_hl, str)
  local hl_group = get_or_create_hl(fg_hl, bg_hl)
  return '%#' .. hl_group .. '#' .. str .. '%#' .. bg_hl .. '#'
end

---@param group_name string
---@param str string
---@return string
M.with_highlight_group = function(group_name, str)
  return '%#' .. group_name .. '#' .. str
end

return M
