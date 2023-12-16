-- Use this file as a minimal nvim config for manual testing
--
-- Installs Lazy package manager
-- Installs triptych with dependencies
-- Install several themes
-- Sets up ]c and [c key bindings to cycle themes
--
-- Usage: nvim -u <path-to-this-file>

---------------------------
-- Options ----------------
---------------------------

vim.g.mapleader = ' '

---------------------------
-- Plugins ----------------
---------------------------

local lazypath = vim.fn.stdpath 'data' .. '/lazy-minimal/lazy.nvim'

if not vim.loop.fs_stat(lazypath) then
  vim.fn.system {
    'git',
    'clone',
    '--filter=blob:none',
    'https://github.com/folke/lazy.nvim.git',
    '--branch=stable',
    lazypath,
  }
end
vim.opt.rtp:prepend(lazypath)

local themes = {
  'tokyonight',
  'tokyonight-day',
  'tokyonight-moon',
  'tokyonight-night',
  'tokyonight-storm',
  'gruvbox',
  'catppuccin',
  'catppuccin-latte',
  'catppuccin-frappe',
  'catppuccin-macchiato',
  'catppuccin-mocha',
}

local selected_theme_index = 1

local function cycle_themes(go_back)
  return function()
    if go_back then
      if selected_theme_index == 1 then
        selected_theme_index = #themes
      else
        selected_theme_index = selected_theme_index - 1
      end
    else
      if selected_theme_index == #themes then
        selected_theme_index = 1
      else
        selected_theme_index = selected_theme_index + 1
      end
    end
    local cmd = 'colorscheme ' .. themes[selected_theme_index]
    vim.cmd(cmd)
    vim.schedule(function()
      vim.print(cmd)
    end)
  end
end

local plugins = {
  {
    'simonmclean/triptych.nvim',
    dir = '~/code/triptych',
    dev = true,
    dependencies = {
      'nvim-lua/plenary.nvim',
      'nvim-tree/nvim-web-devicons',
    },
    config = function()
      require('triptych').setup()
    end,
  },
  -- Themes
  {
    'ellisonleao/gruvbox.nvim',
    priority = 1000,
    config = function()
      vim.cmd('colorscheme ' .. themes[selected_theme_index])
    end,
  },
  {
    'folke/tokyonight.nvim',
    priority = 1000,
    config = function()
      vim.cmd('colorscheme ' .. themes[selected_theme_index])
    end,
  },
  {
    'catppuccin/nvim',
    name = 'catppuccin',
    priority = 1000,
    config = function()
      vim.cmd('colorscheme ' .. themes[selected_theme_index])
    end,
  },
}

require 'lazy'.setup(plugins, {})

---------------------------
-- Mappings ---------------
---------------------------

local map = vim.keymap.set
local silent = { silent = true }

map('n', '|', ':vertical split<cr>', silent)
map('n', '-', ':split<cr>', silent)
map('n', ';', ':')
map('v', ';', ':')
map('n', ']c', cycle_themes(false))
map('n', '[c', cycle_themes(true))
