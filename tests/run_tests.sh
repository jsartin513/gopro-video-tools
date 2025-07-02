#!/bin/bash

# GoPro Video Tools Test Runner
# Runs all test files in the tests directory

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# Source the test framework
source "$SCRIPT_DIR/test_framework.sh"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}GoPro Video Tools Test Suite${NC}"
echo "=================================="
echo ""

# Initialize overall test tracking
TOTAL_TESTS=0
TOTAL_PASSED=0
TOTAL_FAILED=0
SUITE_FAILURES=0

# Function to run a test file
run_test_file() {
    local test_file="$1"
    local test_name=$(basename "$test_file" .sh)
    
    echo -e "${YELLOW}Running: $test_name${NC}"
    echo "----------------------------------------"
    
    # Reset test framework state
    test_init
    
    # Run the test file
    if bash "$test_file"; then
        local exit_code=$?
        
        # Add to totals
        TOTAL_TESTS=$((TOTAL_TESTS + TEST_COUNT))
        TOTAL_PASSED=$((TOTAL_PASSED + PASS_COUNT))
        TOTAL_FAILED=$((TOTAL_FAILED + FAIL_COUNT))
        
        if [[ $FAIL_COUNT -gt 0 ]]; then
            ((SUITE_FAILURES++))
        fi
        
        echo ""
    else
        echo -e "${RED}✗ Test file failed to run: $test_file${NC}"
        ((SUITE_FAILURES++))
        echo ""
    fi
}

# Find and run all test files
test_files_found=0
for test_file in "$SCRIPT_DIR"/test_*.sh; do
    if [[ -f "$test_file" ]]; then
        run_test_file "$test_file"
        ((test_files_found++))
    fi
done

# Print overall summary
echo "=================================="
echo -e "${BLUE}Test Suite Summary${NC}"
echo "=================================="

if [[ $test_files_found -eq 0 ]]; then
    echo -e "${YELLOW}No test files found${NC}"
    exit 0
fi

echo "Total tests: $TOTAL_TESTS"
echo "Passed: $TOTAL_PASSED"
echo "Failed: $TOTAL_FAILED"
echo "Test suites: $test_files_found"
echo "Failed suites: $SUITE_FAILURES"

if [[ $TOTAL_FAILED -eq 0 && $SUITE_FAILURES -eq 0 ]]; then
    echo ""
    echo -e "${GREEN}🎉 All tests passed!${NC}"
    exit 0
else
    echo ""
    echo -e "${RED}❌ Some tests failed${NC}"
    exit 1
fi
