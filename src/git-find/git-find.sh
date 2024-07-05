#!/bin/bash

if [[ "$1" == "--help" ]]; then 
  echo "$0 - help"
  echo "-r, --reflogs - Include reflog entries"
  exit 0
fi 

commits=$(git log --all --format="%h %s")
if [[ "$@" =~ "--reflogs" ]]; then 
  commits+=$(git reflog --all --format="%h (refs) %s")
  echo "refs"
fi

function first_word() {
  return $($1 | awk '{print $1}')
}

commit=$(echo "$commits" | fzf --preview "git log $(first_word {})")

if [[ "$@" =~ "-c" ]]; then
  git checkout $(echo $commit | awk '{print $1}')
else 
  echo $commit 
fi
