#!/bin/bash
# Test suite for AzerothCore Rebuild & Management Script Audit Findings

RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m'

echo -e "${GREEN}Starting Audit Verification Tests...${NC}"

# 1. Test run_command argument splitting
test_run_command() {
    echo -n "Testing run_command argument splitting: "
    run_command_mock() {
        local command_str="$1"
        local -a cmd_parts
        read -r -a cmd_parts <<< "$command_str"
        echo "${#cmd_parts[@]}"
    }
    # "git commit -m 'Fixed bug'" has 4 parts normally: git, commit, -m, "Fixed bug"
    # read -a will split it into 5 parts: git, commit, -m, 'Fixed, bug'
    COUNT=$(run_command_mock "git commit -m 'Fixed bug'")
    if [ "$COUNT" -gt 4 ]; then
        echo -e "${RED}FAILED${NC} (Split 'Fixed bug' into $COUNT pieces)"
    else
        echo -e "${GREEN}PASSED${NC}"
    fi
}

# 2. Test Tilde Expansion
test_tilde_expansion() {
    echo -n "Testing Tilde expansion in variables: "
    BACKUP_DIR="~/ac_backups"
    if [ -d "$BACKUP_DIR" ]; then
        echo -e "${GREEN}PASSED${NC}"
    else
        echo -e "${RED}FAILED${NC} (Literal ~ not expanded in [ -d ])"
    fi
}

# 3. Test find in Restore
test_find_restore() {
    echo -n "Testing find in restore logic: "
    mkdir -p tests/restore_test/dir1 tests/restore_test/dir2
    EXTRACTED_CONTENT_DIR=$(find tests/restore_test -mindepth 1 -maxdepth 1 -type d)
    # This is what the script does: [ -d "$EXTRACTED_CONTENT_DIR" ]
    # bash: [: too many arguments if EXTRACTED_CONTENT_DIR has multiple lines
    if [ -d "$EXTRACTED_CONTENT_DIR" ] 2>/dev/null; then
        echo -e "${GREEN}PASSED${NC}"
    else
        echo -e "${RED}FAILED${NC} (Multiple directories cause [ -d ] to fail)"
    fi
    rm -rf tests/restore_test
}

test_run_command
test_tilde_expansion
test_find_restore

echo -e "${GREEN}Audit Verification Tests Completed.${NC}"
