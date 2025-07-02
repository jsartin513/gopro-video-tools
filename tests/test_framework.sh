#!/bin/bash

# Simple Bash Testing Framework for GoPro Video Tools
# Based on TAP (Test Anything Protocol) format

# Test framework globals
TEST_COUNT=0
PASS_COUNT=0
FAIL_COUNT=0
CURRENT_TEST_NAME=""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Initialize test run
test_init() {
    echo "TAP version 13"
    TEST_COUNT=0
    PASS_COUNT=0
    FAIL_COUNT=0
}

# Set current test name
test_name() {
    CURRENT_TEST_NAME="$1"
}

# Assert that a command succeeds
assert_success() {
    local command="$1"
    local description="${2:-$CURRENT_TEST_NAME}"
    
    ((TEST_COUNT++))
    
    if eval "$command" >/dev/null 2>&1; then
        ((PASS_COUNT++))
        echo -e "ok $TEST_COUNT - ${GREEN}$description${NC}"
        return 0
    else
        ((FAIL_COUNT++))
        echo -e "not ok $TEST_COUNT - ${RED}$description${NC}"
        return 1
    fi
}

# Assert that a command fails
assert_failure() {
    local command="$1"
    local description="${2:-$CURRENT_TEST_NAME}"
    
    ((TEST_COUNT++))
    
    if ! eval "$command" >/dev/null 2>&1; then
        ((PASS_COUNT++))
        echo -e "ok $TEST_COUNT - ${GREEN}$description${NC}"
        return 0
    else
        ((FAIL_COUNT++))
        echo -e "not ok $TEST_COUNT - ${RED}$description${NC}"
        return 1
    fi
}

# Assert that two strings are equal
assert_equals() {
    local expected="$1"
    local actual="$2"
    local description="${3:-$CURRENT_TEST_NAME}"
    
    ((TEST_COUNT++))
    
    if [[ "$expected" == "$actual" ]]; then
        ((PASS_COUNT++))
        echo -e "ok $TEST_COUNT - ${GREEN}$description${NC}"
        return 0
    else
        ((FAIL_COUNT++))
        echo -e "not ok $TEST_COUNT - ${RED}$description${NC}"
        echo -e "  ${YELLOW}Expected:${NC} '$expected'"
        echo -e "  ${YELLOW}Actual:${NC}   '$actual'"
        return 1
    fi
}

# Assert that a string contains a substring
assert_contains() {
    local haystack="$1"
    local needle="$2"
    local description="${3:-$CURRENT_TEST_NAME}"
    
    ((TEST_COUNT++))
    
    if [[ "$haystack" == *"$needle"* ]]; then
        ((PASS_COUNT++))
        echo -e "ok $TEST_COUNT - ${GREEN}$description${NC}"
        return 0
    else
        ((FAIL_COUNT++))
        echo -e "not ok $TEST_COUNT - ${RED}$description${NC}"
        echo -e "  ${YELLOW}String:${NC} '$haystack'"
        echo -e "  ${YELLOW}Does not contain:${NC} '$needle'"
        return 1
    fi
}

# Assert that a file exists
assert_file_exists() {
    local file_path="$1"
    local description="${2:-File exists: $file_path}"
    
    ((TEST_COUNT++))
    
    if [[ -f "$file_path" ]]; then
        ((PASS_COUNT++))
        echo -e "ok $TEST_COUNT - ${GREEN}$description${NC}"
        return 0
    else
        ((FAIL_COUNT++))
        echo -e "not ok $TEST_COUNT - ${RED}$description${NC}"
        echo -e "  ${YELLOW}File not found:${NC} '$file_path'"
        return 1
    fi
}

# Assert that a directory exists
assert_dir_exists() {
    local dir_path="$1"
    local description="${2:-Directory exists: $dir_path}"
    
    ((TEST_COUNT++))
    
    if [[ -d "$dir_path" ]]; then
        ((PASS_COUNT++))
        echo -e "ok $TEST_COUNT - ${GREEN}$description${NC}"
        return 0
    else
        ((FAIL_COUNT++))
        echo -e "not ok $TEST_COUNT - ${RED}$description${NC}"
        echo -e "  ${YELLOW}Directory not found:${NC} '$dir_path'"
        return 1
    fi
}

# Skip a test
skip_test() {
    local reason="$1"
    local description="${2:-$CURRENT_TEST_NAME}"
    
    ((TEST_COUNT++))
    echo -e "ok $TEST_COUNT - ${YELLOW}# SKIP $description - $reason${NC}"
}

# Print test summary
test_summary() {
    echo ""
    echo "1..$TEST_COUNT"
    echo ""
    
    if [[ $FAIL_COUNT -eq 0 ]]; then
        echo -e "${GREEN}✓ All tests passed!${NC} ($PASS_COUNT/$TEST_COUNT)"
        return 0
    else
        echo -e "${RED}✗ Some tests failed.${NC} ($PASS_COUNT passed, $FAIL_COUNT failed out of $TEST_COUNT total)"
        return 1
    fi
}

# Setup function - override in test files
setup() {
    :  # Default no-op
}

# Teardown function - override in test files
teardown() {
    :  # Default no-op
}

# Run a single test function
run_test() {
    local test_function="$1"
    setup
    $test_function
    teardown
}
