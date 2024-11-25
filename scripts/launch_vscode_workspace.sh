#!/bin/bash

workspacesPath=~/Documents/codeworkspaces/

# if not provided workspace
if [ -z "$1" ]; then
  code --new-window
else
  if [ -e "$workspacesPath$1.code-workspace" ]; then
    code "$workspacesPath$1.code-workspace"
  else
    echo "Error: \"$workspacesPath$1.code-workspace\" not found."
  fi
fi
