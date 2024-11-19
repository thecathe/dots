#!/bin/bash

# adapted from: https://unix.stackexchange.com/a/505342

maintainerPath=$"maintain.py"

helpFunction()
{
   echo ""
   echo "Usage: $0 "
   echo -e "\t-b runs backup."
   echo -e "\t-r denote local repo to be rebased."
   echo -e "\t-u updates local system with files in repo."
   echo -e "\t-s runs setup."
   echo -e "\t-h shows help (this)."
   echo -e "\t-p disables push to git at the end of a backup."
   exit 1 # Exit script after printing help
}

# default, if no flags then just run backup
if (( $# == 0 )); then
    echo "python $maintainerPath backup"
    exit 0
fi

while getopts "brushp" opt
do
  case "$opt" in
    b ) bvar=$"backup";;
    r ) rvar=$"rebase";;
    u ) uvar=$"update";;
    s ) svar=$"setup";;
    h ) helpFunction ;;
    p ) pvar=$"dontpush";;
    ? ) helpFunction ;;
  esac
done

python "$maintainerPath" "$bvar" "$rvar" "$uvar" "$svar" "$pvar"
exit 0
