#!/bin/bash

# Use this script to test changes locally

nvim --headless -c 'PlenaryBustedDirectory lua/spec/'
npx @johnnymorganz/stylua-bin --check .
~/.local/share/nvim/mason/bin/lua-language-server --check .
