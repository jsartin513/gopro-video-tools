#!/bin/bash

# Tests for utility scripts (batch_rename_videos.sh, combine_gopro_videos.sh, etc.)

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# Source the test framework
source "$SCRIPT_DIR/test_framework.sh"

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

# Test all utility scripts exist and are executable
test_utility_scripts_exist() {
    local scripts=(
        "batch_rename_videos.sh"
        "combine_gopro_videos.sh"  
        "generate_games_template.sh"
        "split_game_videos.sh"
    )
    
    for script in "${scripts[@]}"; do
        local script_path="$PROJECT_ROOT/bin/$script"
        
        test_name "$script exists"
        assert_file_exists "$script_path" "$script exists"
        
        test_name "$script is executable"
        assert_success "[[ -x '$script_path' ]]" "$script is executable"
        
        test_name "$script has valid syntax"
        assert_success "bash -n '$script_path'" "$script has valid bash syntax"
    done
}

# Test batch rename script
test_batch_rename_script() {
    local script="$PROJECT_ROOT/bin/batch_rename_videos.sh"
    
    test_name "Batch rename shows usage when run without args"
    local output=$("$script" 2>&1 || true)
    # Should either show usage or indicate missing arguments
    assert_success "[[ '$output' =~ [Uu]sage || '$output' =~ [Mm]issing || '$output' =~ [Rr]equired ]]" "Shows usage or error for missing args"
}

# Test combine gopro script
test_combine_gopro_script() {
    local script="$PROJECT_ROOT/bin/combine_gopro_videos.sh"
    
    test_name "Combine GoPro shows usage when run without args"
    local output=$("$script" 2>&1 || true)
    # Should either show usage or indicate missing arguments
    assert_success "[[ '$output' =~ [Uu]sage || '$output' =~ [Mm]issing || '$output' =~ [Rr]equired ]]" "Shows usage or error for missing args"
}

# Test generate games template script
test_generate_games_template_script() {
    local script="$PROJECT_ROOT/bin/generate_games_template.sh"
    
    test_name "Generate games template shows usage when run without args"
    local output=$("$script" 2>&1 || true)
    # Should either show usage or indicate missing arguments  
    assert_success "[[ '$output' =~ [Uu]sage || '$output' =~ [Mm]issing || '$output' =~ [Rr]equired ]]" "Shows usage or error for missing args"
}

# Test split game videos script
test_split_game_videos_script() {
    local script="$PROJECT_ROOT/bin/split_game_videos.sh"
    
    test_name "Split game videos shows usage when run without args"
    local output=$("$script" 2>&1 || true)
    # Should either show usage or indicate missing arguments
    assert_success "[[ '$output' =~ [Uu]sage || '$output' =~ [Mm]issing || '$output' =~ [Rr]equired ]]" "Shows usage or error for missing args"
}

# Test that scripts reference ffmpeg (video processing dependency)
test_ffmpeg_references() {
    local video_scripts=(
        "combine_gopro_videos.sh"
        "split_game_videos.sh"
    )
    
    for script in "${video_scripts[@]}"; do
        local script_path="$PROJECT_ROOT/bin/$script"
        if [[ -f "$script_path" ]]; then
            test_name "$script references ffmpeg"
            local script_content=$(cat "$script_path")
            assert_contains "$script_content" "ffmpeg" "$script references ffmpeg for video processing"
        fi
    done
}

# Test common patterns in utility scripts
test_common_script_patterns() {
    local scripts=(
        "batch_rename_videos.sh"
        "combine_gopro_videos.sh"
        "generate_games_template.sh" 
        "split_game_videos.sh"
    )
    
    for script in "${scripts[@]}"; do
        local script_path="$PROJECT_ROOT/bin/$script"
        if [[ -f "$script_path" ]]; then
            local script_content=$(cat "$script_path")
            
            test_name "$script has shebang"
            assert_contains "$script_content" "#!/bin/bash" "$script has proper bash shebang"
            
            test_name "$script has error handling"
            assert_success "[[ '$script_content' =~ 'set -e' || '$script_content' =~ 'exit' ]]" "$script has some form of error handling"
        fi
    done
}

# Initialize tests
test_init

# Run tests
run_test test_utility_scripts_exist
run_test test_batch_rename_script
run_test test_combine_gopro_script
run_test test_generate_games_template_script
run_test test_split_game_videos_script
run_test test_ffmpeg_references
run_test test_common_script_patterns

# Show results
test_summary
