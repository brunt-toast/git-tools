#!/bin/bash

templates_path="$HOME/.brunt-dotfiles/data/gitignore-templates"

if [ ! -d $templates_path ]; then
    mkdir -p $templates_path 
    git clone https://github.com/github/gitignore $templates_path 
fi

git -C $templates_path pull > /dev/null &

target=$(find $templates_path -name "*.gitignore" | awk -F "/" '{print $NF}' | fzf)

cat $(find $templates_path -name $target) >> ./.gitignore
