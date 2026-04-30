move_note_to_folder() {
	local note_id="$1"
	local folder_path="$2"
	validate_note_id "$note_id" || return 1

	local escaped_folder_path="${folder_path//\"/\\\"}"

	result=$(osascript 2>&1 <<EOF
tell application "Notes"
  try
    set theNote to first note whose id is "$note_id"
    set folderNames to my splitString("$escaped_folder_path", ":")
    set currentFolder to missing value

    repeat with folderName in folderNames
      if currentFolder is missing value then
        set currentFolder to my findOrCreateTopLevelFolder(contents of folderName)
      else
        set currentFolder to my findOrCreateSubFolder(currentFolder, contents of folderName)
      end if
    end repeat

    move theNote to currentFolder
    return id of theNote
  on error errMsg
    error errMsg
  end try

  on splitString(theText, theDelimiter)
    set AppleScript's text item delimiters to theDelimiter
    set theItems to every text item of theText
    set AppleScript's text item delimiters to ""
    return theItems
  end splitString

  on findOrCreateTopLevelFolder(folderName)
    try
      return first folder whose name is folderName
    on error
      return make new folder with properties {name:folderName}
    end try
  end findOrCreateTopLevelFolder

  on findOrCreateSubFolder(parentFolder, folderName)
    try
      return first folder of parentFolder whose name is folderName
    on error
      return make new folder at parentFolder with properties {name:folderName}
    end try
  end findOrCreateSubFolder
end tell
EOF
)

	if [ "$result" = "$note_id" ]; then
		echo "$result"
		return 0
	fi

	echo "Error: Failed to move note $note_id: $result" >&2
	return 1
}
