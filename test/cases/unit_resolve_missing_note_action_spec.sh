#!/usr/bin/env bash

source "$APPROVALS_BASH"
source "$LIB_PATH/resolve_missing_note_action.sh"

describe "resolve_missing_note_action"

  approve "resolve_missing_note_action ''" "resolve_missing_note_action_default"
  approve "resolve_missing_note_action 'ignore'" "resolve_missing_note_action_ignore"
  approve "resolve_missing_note_action 'archive'" "resolve_missing_note_action_archive"
  approve "resolve_missing_note_action 'propagate'" "resolve_missing_note_action_propagate"
