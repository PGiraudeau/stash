get_note_folder_path() {
	local note_id="$1"
	validate_note_id "$note_id" || return 1

	result=$(osascript 2>&1 <<EOF
tell application "Notes"
  try
    set theNote to first note whose id is "$note_id"
    set theFolder to container of theNote
    return my buildFolderPath(theFolder)
  on error
    return ""
  end try

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
)

	if [ -z "$result" ]; then
		return 1
	fi

	echo "$result"
	return 0
}
