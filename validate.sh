#!/bin/bash

# Use this script to test changes locally

echo "Checking formatting..."
npx @johnnymorganz/stylua-bin --check .
formatting_exit_code=$?

if [ $formatting_exit_code -ne 0 ]; then
  echo "❌ 1 or more files are not formatted correctly. Formatting...";
  stylua --config-path stylua.toml --respect-ignores ./
else
  echo "✅ All files are formatted correctly";
fi

echo "Check diagnostics..."
~/.local/share/nvim/mason/bin/lua-language-server --check .

echo "Running tests..."
HEADLESS=true nvim --headless +"so%" tests/run_specs.lua
tests_exit_code=$?

if [ $tests_exit_code -ne 0 ]; then
  echo "❌ 1 or more unit tests failed";
else
  echo "✅ Unit tests passed";
fi
