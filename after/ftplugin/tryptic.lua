local map = vim.keymap.set

map('n', 'h', function()
  require 'tryptic'.nav_to(vim.g.tryptic_state.parent.path)
end)

map('n', 'l', function()
  local target = vim.g.tryptic_state.child
  vim.print('TARGET', target)
  -- if vim.fn.isdirectory(target) == 1 then
  --   require 'tryptic'.nav_to(vim.g.tryptic_state.child.path)
  -- end
end)
