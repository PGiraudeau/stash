#!/usr/bin/env bash

source "$APPROVALS_BASH"
source "$LIB_PATH/print_action_json.sh"

describe "print_action_json"

  approve "print_action_json 'notes/a.md' 'x-coredata://A/ICNote/p1' 'push' 'applied'" "print_action_json_basic"
