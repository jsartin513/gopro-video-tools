#!/bin/bash

# Tests for common.sh utility functions

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# Source the test framework
source "$SCRIPT_DIR/test_framework.sh"

# Source the common utilities
source "$PROJECT_ROOT/bin/common.sh"

# Test setup
setup() {
    # Create temporary test directory
    TEST_TEMP_DIR="/tmp/gopro_test_$$"
    mkdir -p "$TEST_TEMP_DIR"
}

# Test teardown
teardown() {
    # Clean up temporary test directory
    if [[ -d "$TEST_TEMP_DIR" ]]; then
        rm -rf "$TEST_TEMP_DIR"
    fi
}

# Test version functions
test_version_functions() {
    test_name "get_version returns version string"
    local version=$(get_version)
    assert_success "[[ -n '$version' ]]" "Version string is not empty"
    
    test_name "show_version_info displays version"
    local output=$(show_version_info "Test Script" 2>&1)
    assert_contains "$output" "Test Script v" "Version output contains script name and version"
}

# Test logging functions
test_logging_functions() {
    test_name "log_info produces output"
    local output=$(log_info "test message" 2>&1)
    assert_contains "$output" "test message" "log_info contains the message"
    assert_contains "$output" "[INFO]" "log_info contains INFO tag"
    
    test_name "log_success produces output"
    local output=$(log_success "success message" 2>&1)
    assert_contains "$output" "success message" "log_success contains the message"
    assert_contains "$output" "[SUCCESS]" "log_success contains SUCCESS tag"
    
    test_name "log_warning produces output"
    local output=$(log_warning "warning message" 2>&1)
    assert_contains "$output" "warning message" "log_warning contains the message"
    assert_contains "$output" "[WARNING]" "log_warning contains WARNING tag"
    
    test_name "log_error produces output"
    local output=$(log_error "error message" 2>&1)
    assert_contains "$output" "error message" "log_error contains the message"
    assert_contains "$output" "[ERROR]" "log_error contains ERROR tag"
}

# Test color constants
test_color_constants() {
    test_name "Color constants are defined"
    assert_success "[[ -n '$RED' ]]" "RED color constant is defined"
    assert_success "[[ -n '$GREEN' ]]" "GREEN color constant is defined"
    assert_success "[[ -n '$YELLOW' ]]" "YELLOW color constant is defined"
    assert_success "[[ -n '$BLUE' ]]" "BLUE color constant is defined"
    assert_success "[[ -n '$NC' ]]" "NC (no color) constant is defined"
}

# Initialize tests
test_init

# Run tests
run_test test_version_functions
run_test test_logging_functions
run_test test_color_constants

# Show results
test_summary
