#!/bin/bash

RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m' # No Color

# Check for git repo
if [ -d ".git" ] || git rev-parse --git-dir >/dev/null 2>&1; then
	: # pass
else
	echo -e "${RED}FATAL:${NC} Not a git repository"
	exit 1
fi

# Check for branch head
if git symbolic-ref -q HEAD >/dev/null 2>&1; then
	: # pass
else
	echo -e "${RED}FATAL:${NC} Not a branch head"
	exit 1
fi

git_backup() {
	# Store info about the current state
	old_branch=$(git rev-parse --abbrev-ref HEAD)
	latest_commit_message=$(git log -1 --pretty=%B)
	latest_commit_hash=$(git rev-parse HEAD)

	# Compute info about the new state
	new_branch="backup/${old_branch}/$(date +%s%N)"
	new_commit_message="Backup atop ${latest_commit_hash} at $(date)"

	# Create the backup
	git add --all
	git commit -m "$new_commit_message"
	git tag $new_branch
	git reset --soft $latest_commit_hash
	git reset
}

git_backup_delete_all() {
	git tag | rg "^(\s+)?backup/" | xargs git tag -d
}

if [[ "$@" == *"--drop"* ]]; then
	git_backup_delete_all
	exit 0
fi

git_backup >>/dev/null 2>&1
echo -e "${GREEN}Success${NC}"
echo "Created backup of working state"
