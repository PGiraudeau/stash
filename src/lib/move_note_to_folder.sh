move_note_to_folder() {
	local note_id="$1"
	local folder_path="$2"
	validate_note_id "$note_id" || return 1

	local escaped_folder_path="${folder_path//\"/\\\"}"

	result=$(printf 'tell application "Notes"\n  try\n    set theNote to first note whose id is "%s"\n    set folderNames to my splitString("%s", ":")\n    set currentFolder to missing value\n\n    repeat with folderName in folderNames\n      if currentFolder is missing value then\n        set currentFolder to my findOrCreateTopLevelFolder(contents of folderName)\n      else\n        set currentFolder to my findOrCreateSubFolder(currentFolder, contents of folderName)\n      end if\n    end repeat\n\n    move theNote to currentFolder\n    return id of theNote\n  on error errMsg\n    error errMsg\n  end try\nend tell\n\non splitString(theText, theDelimiter)\n  set AppleScript'"'"'s text item delimiters to theDelimiter\n  set theItems to every text item of theText\n  set AppleScript'"'"'s text item delimiters to ""\n  return theItems\nend splitString\n\non findOrCreateTopLevelFolder(folderName)\n  tell application "Notes"\n    try\n      return first folder whose name is folderName\n    on error\n      return make new folder with properties {name:folderName}\n    end try\n  end tell\nend findOrCreateTopLevelFolder\n\non findOrCreateSubFolder(parentFolder, folderName)\n  tell application "Notes"\n    try\n      return first folder of parentFolder whose name is folderName\n    on error\n      return make new folder at parentFolder with properties {name:folderName}\n    end try\n  end tell\nend findOrCreateSubFolder\n' \
		"$note_id" "$escaped_folder_path" | osascript 2>&1 || true)

	if [ "$result" = "$note_id" ]; then
		echo "$result"
		return 0
	fi

	echo "Error: Failed to move note $note_id: $result" >&2
	return 1
}
