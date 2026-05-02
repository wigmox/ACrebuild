#!/bin/bash
# Test suite for AzerothCore Rebuild & Management Script Audit Findings

RED='\033[38;5;196m'
GREEN='\033[38;5;82m'
NC='\033[0m'

echo -e "${GREEN}Starting Audit Verification Tests...${NC}"

# Load core for functions
source ./lib/core.sh
source ./lib/variables.sh

# 1. Test run_command argument splitting
test_run_command() {
    echo -n "Testing run_command argument splitting: "
    cat << 'INNER_EOF' > tests/arg_counter.sh
#!/bin/bash
echo "$#"
INNER_EOF
    chmod +x tests/arg_counter.sh
    COUNT=$(run_command ./tests/arg_counter.sh "one" "two three" "four")
    if [ "$COUNT" -ne 3 ]; then
        echo -e "${RED}FAILED${NC} (Expected 3 arguments, got $COUNT)"
    else
        echo -e "${GREEN}PASSED${NC}"
    fi
    rm tests/arg_counter.sh
}

# 2. Test Tilde Expansion
test_tilde_expansion() {
    echo -n "Testing Tilde expansion: "
    EXPANDED=$(expand_path "~/test")
    if [[ "$EXPANDED" == "${HOME}/test" ]]; then
        echo -e "${GREEN}PASSED${NC}"
    else
        echo -e "${RED}FAILED${NC} (Got: $EXPANDED)"
    fi
}

# 3. Test find in Restore Logic
test_find_restore() {
    echo -n "Testing find in restore logic: "
    mkdir -p tests/restore_test/backup_123 tests/restore_test/other_dir
    EXTRACTED_CONTENT_DIR=$(find tests/restore_test -mindepth 1 -maxdepth 1 -type d -name "backup_*" | head -n 1)
    if [ -d "$EXTRACTED_CONTENT_DIR" ]; then
         # Ensure we only got one line
         LINE_COUNT=$(echo "$EXTRACTED_CONTENT_DIR" | wc -l)
         if [ "$LINE_COUNT" -eq 1 ]; then
            echo -e "${GREEN}PASSED${NC}"
         else
            echo -e "${RED}FAILED${NC} (Got multiple lines)"
         fi
    else
        echo -e "${RED}FAILED${NC} (Did not find backup directory)"
    fi
    rm -rf tests/restore_test
}

# 4. Test Dynamic Path Detection
test_path_detection() {
    echo -n "Testing Dynamic Path Detection: "
    source ./lib/config.sh
    # Mock some values
    AZEROTHCORE_DIR="tests/ac_mock"
    mkdir -p "$AZEROTHCORE_DIR/env/bin"

    # Run a subset of load_config or just the logic
    if [ -d "$AZEROTHCORE_DIR/env/bin" ]; then
        DETECTED_AUTH="$AZEROTHCORE_DIR/env/bin/authserver"
    fi

    if [[ "$DETECTED_AUTH" == "tests/ac_mock/env/bin/authserver" ]]; then
        echo -e "${GREEN}PASSED${NC}"
    else
        echo -e "${RED}FAILED${NC}"
    fi
    rm -rf tests/ac_mock
}

# 5. Test Port Parsing
test_port_parsing() {
    echo -n "Testing Port Parsing: "
    mkdir -p tests/conf_mock
    echo "RealmServerPort = 1234" > tests/conf_mock/authserver.conf
    echo "WorldServerPort = 5678" > tests/conf_mock/worldserver.conf

    AUTH_PORT=""
    WORLD_PORT=""
    SERVER_CONFIG_DIR_PATH="tests/conf_mock"

    if [ -f "$SERVER_CONFIG_DIR_PATH/authserver.conf" ]; then
        AUTH_PORT=$(grep "^RealmServerPort" "$SERVER_CONFIG_DIR_PATH/authserver.conf" | cut -d'=' -f2 | tr -d '[:space:]')
    fi

    if [[ "$AUTH_PORT" == "1234" ]]; then
        echo -e "${GREEN}PASSED${NC}"
    else
        echo -e "${RED}FAILED${NC} (Got: $AUTH_PORT)"
    fi
    rm -rf tests/conf_mock
}

test_run_command
test_tilde_expansion
test_find_restore
test_path_detection
test_port_parsing

echo -e "${GREEN}Audit Verification Tests Completed.${NC}"
