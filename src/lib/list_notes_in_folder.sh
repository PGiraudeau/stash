list_notes_in_folder() {
	local base_folder="$1"
	local escaped_base_folder="${base_folder//\"/\\\"}"

	osascript 2>&1 <<EOF
tell application "Notes"
  try
    set outLines to {}
    if "$escaped_base_folder" is "" then
      set roots to folders
      repeat with f in roots
        set outLines to my emitFolder(f, outLines)
      end repeat
    else
      set folderNames to my splitString("$escaped_base_folder", ":")
      set currentFolder to missing value
      repeat with folderName in folderNames
        if currentFolder is missing value then
          set currentFolder to first folder whose name is (contents of folderName)
        else
          set currentFolder to first folder of currentFolder whose name is (contents of folderName)
        end if
      end repeat
      set outLines to my emitFolder(currentFolder, outLines)
    end if
    set AppleScript's text item delimiters to linefeed
    return outLines as text
  on error
    return ""
  end try

  on emitFolder(aFolder, outLines)
    set folderPath to my buildFolderPath(aFolder)
    repeat with n in notes of aFolder
      set noteId to id of n
      set noteName to name of n
      set end of outLines to noteId & "|" & folderPath & "|" & noteName
    end repeat
    repeat with sf in folders of aFolder
      set outLines to my emitFolder(sf, outLines)
    end repeat
    return outLines
  end emitFolder

  on splitString(theText, theDelimiter)
    set AppleScript's text item delimiters to theDelimiter
    set theItems to every text item of theText
    set AppleScript's text item delimiters to ""
    return theItems
  end splitString

  on buildFolderPath(aFolder)
    set folderName to name of aFolder
    try
      set parentFolder to container of aFolder
      if class of parentFolder is folder then
        return (my buildFolderPath(parentFolder)) & ":" & folderName
      else
        return folderName
      end if
    on error
      return folderName
    end try
  end buildFolderPath
end tell
EOF
}
