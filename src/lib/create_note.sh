create_note() {
	local content="$1"
	local folder_path="$2"
	
	# Escape double quotes for AppleScript string
	local escaped_content="${content//\"/\\\"}"
	local escaped_folder_path="${folder_path//\"/\\\"}"
	
	result=$(osascript 2>&1 <<EOF
tell application "Notes"
  try
    set targetFolder to missing value

    if "$escaped_folder_path" is not "" then
      set folderNames to my splitString("$escaped_folder_path", ":")
      set currentFolder to missing value

      repeat with folderName in folderNames
        if currentFolder is missing value then
          set currentFolder to my findOrCreateTopLevelFolder(contents of folderName)
        else
          set currentFolder to my findOrCreateSubFolder(currentFolder, contents of folderName)
        end if
      end repeat

      set targetFolder to currentFolder
    end if

    if targetFolder is missing value then
      set newNote to make new note with properties {body:"$escaped_content"}
    else
      set newNote to make new note at targetFolder with properties {body:"$escaped_content"}
    end if

    return id of newNote
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
	
	# Check if result looks like a valid note ID
	if [[ "$result" =~ ^x-coredata:// ]]; then
		echo "$result"
		return 0
	else
		echo "Error: Failed to create note: $result" >&2
		return 1
	fi
}
