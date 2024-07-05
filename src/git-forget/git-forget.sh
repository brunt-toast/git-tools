#!/bin/bash

if ! git -C "$1" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  echo "Fatal: not a git repo"
  exit 1
fi

echo "Indexing repo $1..."
mapfile -t files < <(find "$1" -type f)
echo "Found ${#files[@]} files."

echo "Checking files against ignore criteria..."
ignored_files=()
for file in "${files[@]}"; do 
  git check-ignore --no-index "$file" > /dev/null && ignored_files+=("$file")
done
if [ "${#ignored_files[@]}" -le 0 ]; then 
  echo "Didn't find any ignored files. Nothing to do."
  exit 0 
fi 
echo "Narrowed to ${#ignored_files[@]} files fitting ignore criteria."

echo "Checking if files are tracked..."
staged_files=() 
for file in "${ignored_files[@]}"; do 
  git ls-files --error-unmatch "$file" > /dev/null 2>&1 && staged_files+=("$file")
done 
if [ "${#staged_files[@]}" -le 0 ]; then 
  echo "All files fitting ignore criteria are untracked. Nothing to do."
  exit 0 
fi 
echo "Narrowed to ${#staged_files[@]} files to be forgotten."

failed=()
for file in "${staged_files[@]}"; do 
  git rm "$file" > /dev/null 2>&1 || failed+=$("$file")
done

if [ "${#failed[@]}" -gt 0 ]; then 
  echo "WARNING: ${#failed[@]} files could not be removed:"
  for file in "${failed[@]}"; do 
    echo -e "\t$file"
  done
fi

echo "Forget complete."
