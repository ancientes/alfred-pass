#!/usr/bin/env bash

# goto git root
cd "$(git rev-parse --show-toplevel)" || return 1

# Prompt for next version number
current_version=$(plutil -extract version xml1 -o - info.plist | sed -n 's/.*<string>\(.*\)<\/string>.*/\1/p')
workflow_name=$(plutil -extract name xml1 -o - info.plist | sed -n 's/.*<string>\(.*\)<\/string>.*/\1/p')
echo "current version: $current_version"
echo -n "   next version: "
read -r next_version
echo "────────────────────────"

# GUARD
if [[ -z "$next_version" || "$next_version" == "$current_version" ]]; then
	echo -e "\033[1;31mInvalid version number.\033[0m"
	return 1
fi

# update version number in THE REPO'S `info.plist`
plutil -replace version -string "$next_version" info.plist

# INFO this assumes the local folder is named the same as the github repo
# 1. update version number in LOCAL `info.plist`
# 2. convenience: copy download link for current version

# update version number in LOCAL `info.plist`
prefs_location=$(defaults read com.runningwithcrayons.Alfred-Preferences syncfolder | sed "s|^~|$HOME|")
workflows_dir="$prefs_location/Alfred.alfredpreferences/workflows"

# Find the workflow folder that matches the current workflow name
workflow_uid=""
for folder in "$workflows_dir"/*; do
	if [ -f "$folder/info.plist" ]; then
		folder_workflow_name=$(plutil -extract name xml1 -o - "$folder/info.plist" | sed -n 's/.*<string>\(.*\)<\/string>.*/\1/p')
		if [ "$folder_workflow_name" = "$workflow_name" ]; then
			workflow_uid=$(basename "$folder")
			break
		fi
	fi
done

local_info_plist="$workflows_dir/$workflow_uid/info.plist"
if [[ -f "$local_info_plist" ]] ; then 
	plutil -replace version -string "$next_version" "$local_info_plist"
else
	echo -e "\033[1;33mCould not increment version, local \`info.plist\` not found: '$local_info_plist'\033[0m"
fi

# commit and push
git add --all &&
	git commit -m "release: $next_version" &&
	git pull --no-progress &&
	git push --no-progress &&
	git tag "$next_version" -m "release: $next_version" && # pushing a tag triggers the github release action
	git push --no-progress origin --tags