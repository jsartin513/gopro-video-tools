#!/bin/bash

# Tests for configuration system

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# Source the test framework
source "$SCRIPT_DIR/test_framework.sh"

CONFIG_FILE="$PROJECT_ROOT/config/gopro_config.conf"

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

# Test configuration file exists
test_config_file_exists() {
    test_name "Configuration file exists"
    assert_file_exists "$CONFIG_FILE" "gopro_config.conf exists"
    
    test_name "Configuration directory exists"
    assert_dir_exists "$PROJECT_ROOT/config" "config directory exists"
}

# Test configuration file content
test_config_file_content() {
    if [[ ! -f "$CONFIG_FILE" ]]; then
        skip_test "Configuration file not found" "Config file content tests"
        return
    fi
    
    local config_content=$(cat "$CONFIG_FILE")
    
    test_name "Config has tournament name setting"
    assert_contains "$config_content" "DEFAULT_TOURNAMENT_NAME" "Config contains tournament name setting"
    
    test_name "Config has court name setting"
    assert_contains "$config_content" "DEFAULT_COURT_NAME" "Config contains court name setting"
    
    test_name "Config has round name setting"
    assert_contains "$config_content" "DEFAULT_ROUND_NAME" "Config contains round name setting"
    
    test_name "Config has workflow options"
    assert_contains "$config_content" "AUTO_ADD_METADATA" "Config contains auto add metadata option"
    assert_contains "$config_content" "AUTO_RENAME_FILES" "Config contains auto rename files option"
    
    test_name "Config has video processing options"
    assert_contains "$config_content" "DEFAULT_GAME_DURATION" "Config contains game duration setting"
    assert_contains "$config_content" "FFMPEG_QUALITY" "Config contains ffmpeg quality setting"
}

# Test configuration file format
test_config_file_format() {
    if [[ ! -f "$CONFIG_FILE" ]]; then
        skip_test "Configuration file not found" "Config file format tests"
        return
    fi
    
    test_name "Config file has proper format"
    # Should be sourceable by bash without errors
    assert_success "bash -n '$CONFIG_FILE'" "Config file has valid bash syntax"
    
    test_name "Config can be sourced"
    # Test that we can source it in a subshell without errors
    assert_success "(source '$CONFIG_FILE')" "Config file can be sourced"
}

# Test configuration values
test_config_values() {
    if [[ ! -f "$CONFIG_FILE" ]]; then
        skip_test "Configuration file not found" "Config values tests"
        return
    fi
    
    # Source the config in a subshell and test values
    local test_result
    
    test_name "Tournament name has default value"
    test_result=$(source "$CONFIG_FILE" && echo "$DEFAULT_TOURNAMENT_NAME")
    assert_success "[[ -n '$test_result' ]]" "Tournament name has a value"
    
    test_name "Court name has default value"
    test_result=$(source "$CONFIG_FILE" && echo "$DEFAULT_COURT_NAME")
    assert_success "[[ -n '$test_result' ]]" "Court name has a value"
    
    test_name "Round name has default value"
    test_result=$(source "$CONFIG_FILE" && echo "$DEFAULT_ROUND_NAME")
    assert_success "[[ -n '$test_result' ]]" "Round name has a value"
}

# Test that comments are preserved
test_config_comments() {
    if [[ ! -f "$CONFIG_FILE" ]]; then
        skip_test "Configuration file not found" "Config comments tests"
        return
    fi
    
    local config_content=$(cat "$CONFIG_FILE")
    
    test_name "Config file has documentation"
    assert_contains "$config_content" "#" "Config file contains comments for documentation"
    
    test_name "Config file has section headers"
    # Look for comment sections like "# Default metadata values"
    assert_success "[[ '$config_content' =~ '#'.*[Dd]efault || '$config_content' =~ '#'.*[Oo]ptions || '$config_content' =~ '#'.*[Ss]ettings ]]" "Config has section documentation"
}

# Initialize tests
test_init

# Run tests
run_test test_config_file_exists
run_test test_config_file_content
run_test test_config_file_format
run_test test_config_values
run_test test_config_comments

# Show results
test_summary
