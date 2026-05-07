create_note() {
	local content="$1"
	local folder_path="$2"

	# Strip newlines (AppleScript strings cannot span lines) and escape quotes
	local escaped_content="${content//$'\n'/}"
	escaped_content="${escaped_content//\"/\\\"}"
	local escaped_folder_path="${folder_path//\"/\\\"}"

	# Build AppleScript and pipe to osascript to avoid heredoc escaping issues
	result=$(printf 'tell application "Notes"\n  try\n    set targetFolder to missing value\n\n    if "%s" is not "" then\n      set folderNames to my splitString("%s", ":")\n      set currentFolder to missing value\n\n      repeat with folderName in folderNames\n        if currentFolder is missing value then\n          set currentFolder to my findOrCreateTopLevelFolder(contents of folderName)\n        else\n          set currentFolder to my findOrCreateSubFolder(currentFolder, contents of folderName)\n        end if\n      end repeat\n\n      set targetFolder to currentFolder\n    end if\n\n    if targetFolder is missing value then\n      set newNote to make new note with properties {body:"%s"}\n    else\n      set newNote to make new note at targetFolder with properties {body:"%s"}\n    end if\n\n    return id of newNote\n  on error errMsg\n    error errMsg\n  end try\nend tell\n\non splitString(theText, theDelimiter)\n  set AppleScript'"'"'s text item delimiters to theDelimiter\n  set theItems to every text item of theText\n  set AppleScript'"'"'s text item delimiters to ""\n  return theItems\nend splitString\n\non findOrCreateTopLevelFolder(folderName)\n  tell application "Notes"\n    try\n      return first folder whose name is folderName\n    on error\n      return make new folder with properties {name:folderName}\n    end try\n  end tell\nend findOrCreateTopLevelFolder\n\non findOrCreateSubFolder(parentFolder, folderName)\n  tell application "Notes"\n    try\n      return first folder of parentFolder whose name is folderName\n    on error\n      return make new folder at parentFolder with properties {name:folderName}\n    end try\n  end tell\nend findOrCreateSubFolder\n' \
		"$escaped_folder_path" "$escaped_folder_path" "$escaped_content" "$escaped_content" | osascript 2>&1 || true)

	# Check if result looks like a valid note ID
	if [[ "$result" =~ ^x-coredata:// ]]; then
		echo "$result"
		return 0
	else
		echo "Error: Failed to create note: $result" >&2
		return 1
	fi
}
