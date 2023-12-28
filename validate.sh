#!/bin/bash

# Use this script to test changes locally

echo "Running unit tests..."
nvim --headless -c 'PlenaryBustedDirectory lua/spec/'
test_exit_code=$?
if [ $test_exit_code -ne 0 ]; then
  echo "❌ 1 or more unit tests failed";
else
  echo "✅ Unit tests passed";
fi

echo "Running UI tests..."
nvim --headless -c 'PlenaryBustedFile ui_tests/tests.lua'
test_exit_code=$?
if [ $test_exit_code -ne 0 ]; then
  echo "❌ 1 or more UI tests failed";
else
  echo "✅ UI tests passed";
fi

echo "Checking formatting..."
npx @johnnymorganz/stylua-bin --check .

echo "Check diagnostics..."
~/.local/share/nvim/mason/bin/lua-language-server --check .
