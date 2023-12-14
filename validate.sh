#!/bin/bash

# Use this script to test changes locally

echo "Running tests..."
nvim --headless -c 'PlenaryBustedDirectory lua/spec/'
test_exit_code=$?
if [ $test_exit_code -ne 0 ]; then
  echo "❌ 1 or more tests failed";
else
  echo "✅ Tests passed";
fi

echo "Checking formatting..."
npx @johnnymorganz/stylua-bin --check .

echo "Check diagnostics..."
~/.local/share/nvim/mason/bin/lua-language-server --check .
