#!/bin/bash

all_tests_pass=true

for test_path in ./lua/spec/*
do
  nvim --headless -c "PlenaryBustedFile $test_path" | grep "Failed" | grep -v "0" > /dev/null
  if [ $? -eq 0 ]
  then
    all_tests_pass=false
    echo "Tests failed in $test_path"
  fi
done

if [ "$all_tests_pass" = false ]
then
  exit 1
else
  echo "Success: All tests passing 🎉"
  exit 0
fi
