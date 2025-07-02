#!/bin/bash

# Tests for gopro_workflow.sh main script

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# Source the test framework
source "$SCRIPT_DIR/test_framework.sh"

WORKFLOW_SCRIPT="$PROJECT_ROOT/bin/gopro_workflow.sh"

# Test setup
setup() {
    TEST_TEMP_DIR="/tmp/gopro_test_$$"
    mkdir -p "$TEST_TEMP_DIR"
}

# Test teardown
teardown() {
    if [[ -d "$TEST_TEMP_DIR" ]]; then
        rm -rf "$TEST_TEMP_DIR"
    fi
}

# Test script existence and permissions
test_script_basics() {
    test_name "Workflow script exists"
    assert_file_exists "$WORKFLOW_SCRIPT" "gopro_workflow.sh exists"
    
    test_name "Workflow script is executable"
    assert_success "[[ -x '$WORKFLOW_SCRIPT' ]]" "gopro_workflow.sh is executable"
}

# Test command line help
test_help_functionality() {
    test_name "Help flag works"
    local output=$("$WORKFLOW_SCRIPT" --help 2>&1)
    local exit_code=$?
    
    assert_equals "0" "$exit_code" "Help command exits with code 0"
    assert_contains "$output" "Usage:" "Help output contains usage information"
    assert_contains "$output" "INDIVIDUAL MATCH MODE" "Help mentions Individual Match Mode"
    assert_contains "$output" "TOURNAMENT RECORDING MODE" "Help mentions Tournament Recording Mode"
}

# Test version functionality
test_version_functionality() {
    test_name "Version flag works"
    local output=$("$WORKFLOW_SCRIPT" --version 2>&1)
    local exit_code=$?
    
    assert_equals "0" "$exit_code" "Version command exits with code 0"
    assert_contains "$output" "GoPro Video Processing Workflow" "Version output contains script name"
    
    # Extract version dynamically and validate format
    local version=$(echo "$output" | grep -oE "v[0-9]+\.[0-9]+\.[0-9]+")
    assert_not_empty "$version" "Version output contains a valid version number"
    assert_success "[[ $version =~ ^v[0-9]+\.[0-9]+\.[0-9]+$ ]]" "Version number matches expected format"
}

# Test error handling
test_error_handling() {
    test_name "Missing directory argument shows usage"
    assert_failure "$WORKFLOW_SCRIPT" "Missing argument fails (exits with non-zero code)"
    
    local output=$("$WORKFLOW_SCRIPT" 2>&1 || true)
    assert_contains "$output" "Usage:" "Missing argument shows usage"
    
    test_name "Non-existent directory shows error" 
    assert_failure "$WORKFLOW_SCRIPT /nonexistent/directory/12345" "Non-existent directory fails (exits with non-zero code)"
    
    local output=$("$WORKFLOW_SCRIPT" "/nonexistent/directory/12345" 2>&1 || true)
    assert_contains "$output" "Directory not found" "Error message for non-existent directory"
}

# Test configuration file handling
test_config_handling() {
    test_name "Custom config file path works"
    # Create a temporary config file
    local temp_config="$TEST_TEMP_DIR/test_config.conf"
    echo "DEFAULT_TOURNAMENT_NAME=\"Test Tournament\"" > "$temp_config"
    
    # Test only the help output with the custom config to avoid interactive mode
    local output=$("$WORKFLOW_SCRIPT" -c "$temp_config" --help 2>&1)
    local exit_code=$?
    
    # The script should parse the config argument and then show help
    assert_equals "0" "$exit_code" "Custom config with help flag exits successfully"
    assert_contains "$output" "Usage:" "Help is shown when config is specified"
}

# Test syntax validation
test_syntax_validation() {
    test_name "Script has valid bash syntax"
    assert_success "bash -n '$WORKFLOW_SCRIPT'" "gopro_workflow.sh has valid syntax"
}

# Initialize tests
test_init

# Run tests
run_test test_script_basics
run_test test_help_functionality  
run_test test_version_functionality
run_test test_error_handling
run_test test_config_handling
run_test test_syntax_validation

# Show results
test_summary
