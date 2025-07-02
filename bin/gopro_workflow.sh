#!/bin/bash

# GoPro Video Processing Workflow
# Automates the entire process from raw GoPro videos to split game videos
# Version: 1.0.0

set -e  # Exit on any error

# Version and script info
VERSION="1.0.0"
SCRIPT_NAME="GoPro Video Processing Workflow"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_FILE="$SCRIPT_DIR/../config/gopro_config.conf"

# Try to read version from VERSION file if it exists
if [[ -f "$SCRIPT_DIR/../VERSION" ]]; then
    VERSION=$(cat "$SCRIPT_DIR/../VERSION" | tr -d '\n\r')
fi

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Helper functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Version and help functions
show_version() {
    echo "$SCRIPT_NAME v$VERSION"
    echo "Copyright (c) 2025 Jessica Sartin"
}

show_help() {
    show_version
    echo ""
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  -h, --help     Show this help message"
    echo "  -v, --version  Show version information"
    echo "  -c, --config   Specify config file (default: ../config/gopro_config.conf)"
    echo ""
    echo "This script automates the entire GoPro video processing workflow:"
    echo "1. Batch rename raw GoPro files"
    echo "2. Combine multi-part videos"
    echo "3. Split combined videos into individual games"
    echo "4. Apply metadata and organize files"
    echo ""
}

# Load configuration
load_config() {
    if [[ -f "$CONFIG_FILE" ]]; then
        source "$CONFIG_FILE"
        log_info "Loaded configuration from $CONFIG_FILE"
    else
        log_warning "No configuration file found. Using defaults."
        # Set defaults
        DEFAULT_TOURNAMENT_NAME="Tournament"
        DEFAULT_COURT_NAME="Court"
        DEFAULT_ROUND_NAME="Round"
    fi
}

# Create configuration file if it doesn't exist
create_config() {
    if [[ ! -f "$CONFIG_FILE" ]]; then
        cat > "$CONFIG_FILE" << EOF
# GoPro Workflow Configuration
DEFAULT_TOURNAMENT_NAME="Tournament"
DEFAULT_COURT_NAME="Court"  
DEFAULT_ROUND_NAME="Round"
AUTO_ADD_METADATA=true
CLEANUP_INTERMEDIATE_FILES=false
EOF
        log_success "Created configuration file: $CONFIG_FILE"
    fi
}

# Fix directory names by replacing spaces with underscores
fix_directory_names() {
    local input_dir="$1"
    local fixed=false
    
    log_info "Checking for spaces in directory names..."
    
    # Find directories with spaces and rename them
    find "$input_dir" -type d -name "* *" | while IFS= read -r dir; do
        new_dir="${dir// /_}"
        if [[ "$dir" != "$new_dir" ]]; then
            log_info "Renaming: '$dir' -> '$new_dir'"
            mv "$dir" "$new_dir"
            fixed=true
        fi
    done
    
    # Also fix filenames with spaces
    find "$input_dir" -type f -name "* *" | while IFS= read -r file; do
        dir=$(dirname "$file")
        filename=$(basename "$file")
        new_filename="${filename// /_}"
        if [[ "$filename" != "$new_filename" ]]; then
            log_info "Renaming file: '$filename' -> '$new_filename'"
            mv "$file" "$dir/$new_filename"
            fixed=true
        fi
    done
    
    if [[ "$fixed" == "true" ]]; then
        log_success "Fixed directory and file names"
    else
        log_info "No spaces found in names"
    fi
}

# Interactive JSONL creation
create_games_jsonl() {
    local jsonl_file="$1"
    local temp_file=$(mktemp)
    
    log_info "Creating games JSONL file: $jsonl_file"
    echo "Enter game information (press Enter with empty team name to finish):"
    
    while true; do
        echo
        read -p "Home team: " home_team
        [[ -z "$home_team" ]] && break
        
        read -p "Away team: " away_team
        [[ -z "$away_team" ]] && break
        
        read -p "Start time (HH:MM): " start_time
        while [[ ! "$start_time" =~ ^[0-9]{2}:[0-9]{2}$ ]]; do
            read -p "Invalid format. Start time (HH:MM): " start_time
        done
        
        read -p "Duration in minutes [60]: " minutes
        minutes=${minutes:-60}
        
        # Create JSON entry
        echo "{\"home_team\":\"$home_team\",\"away_team\":\"$away_team\",\"start_time\":\"$start_time\",\"minutes\":$minutes}" >> "$temp_file"
        
        log_success "Added game: $home_team vs $away_team"
    done
    
    if [[ -s "$temp_file" ]]; then
        mv "$temp_file" "$jsonl_file"
        log_success "Games JSONL file created: $jsonl_file"
    else
        rm "$temp_file"
        log_warning "No games added"
        return 1
    fi
}

# Load games from existing JSONL or create new one
prepare_games_jsonl() {
    local video_dir="$1"
    local jsonl_file="$video_dir/games.jsonl"
    
    if [[ -f "$jsonl_file" ]]; then
        read -p "Games JSONL file exists. Use existing? (y/n) [y]: " use_existing
        use_existing=${use_existing:-y}
        
        if [[ "$use_existing" =~ ^[Yy] ]]; then
            log_info "Using existing games file: $jsonl_file"
            return 0
        fi
    fi
    
    create_games_jsonl "$jsonl_file"
}

# Add metadata to video files
add_video_metadata() {
    local split_dir="$1"
    local tournament_name="$2"
    local court_name="$3"
    local round_name="$4"
    
    if [[ "$AUTO_ADD_METADATA" != "true" ]]; then
        return 0
    fi
    
    log_info "Adding metadata to video files..."
    
    for video_file in "$split_dir"/*.mp4; do
        [[ -f "$video_file" ]] || continue
        
        local file_base=$(basename "$video_file" .mp4)
        local temp_file="${video_file%.mp4}_temp.mp4"
        
        # Extract team names from filename
        local teams=$(echo "$file_base" | sed 's/_vs_/ vs /')
        
        log_info "Adding metadata to: $file_base"
        
        ffmpeg -hide_banner -loglevel error -i "$video_file" \
            -metadata title="$teams - $tournament_name $round_name" \
            -metadata description="$tournament_name - $round_name - $court_name" \
            -metadata comment="Generated by GoPro Workflow" \
            -c copy "$temp_file"
        
        mv "$temp_file" "$video_file"
    done
    
    log_success "Added metadata to all videos"
}

# Rename video files with tournament/round/court information
rename_video_files() {
    local split_dir="$1"
    local tournament_name="$2"
    local court_name="$3"
    local jsonl_file="$4"
    local start_round="$5"
    
    log_info "Renaming video files with tournament information..."
    
    local count=0
    local current_round="$start_round"
    
    for video_file in "$split_dir"/*.mp4; do
        [[ -f "$video_file" ]] || continue
        
        local original_name=$(basename "$video_file")
        local base_name="${original_name%.*}"
        local extension="${original_name##*.}"
        
        # Try to extract round from JSONL file based on team names
        local round_from_jsonl=""
        if [[ -f "$jsonl_file" ]]; then
            # Extract team names from filename (assuming format: Team1_vs_Team2.mp4)
            local team1=$(echo "$base_name" | sed 's/_vs_.*//')
            local team2=$(echo "$base_name" | sed 's/.*_vs_//')
            
            # Look for round information in JSONL
            round_from_jsonl=$(jq -r --arg team1 "$team1" --arg team2 "$team2" \
                'select(.home_team == $team1 and .away_team == $team2) | .round // empty' \
                "$jsonl_file" 2>/dev/null || echo "")
            
            # If not found, try the reverse (away vs home)
            if [[ -z "$round_from_jsonl" ]]; then
                round_from_jsonl=$(jq -r --arg team1 "$team2" --arg team2 "$team1" \
                    'select(.home_team == $team1 and .away_team == $team2) | .round // empty' \
                    "$jsonl_file" 2>/dev/null || echo "")
            fi
        fi
        
        # Use round from JSONL if available, otherwise use incremental round
        local round_name=""
        if [[ -n "$round_from_jsonl" ]]; then
            round_name="$round_from_jsonl"
        else
            round_name="Game_$current_round"
            ((current_round++))
        fi
        
        local new_name=""
        
        # Build new name: Tournament_Round_Court_OriginalName.ext
        if [[ -n "$tournament_name" ]]; then
            new_name="${tournament_name}"
        fi
        
        if [[ -n "$round_name" ]]; then
            [[ -n "$new_name" ]] && new_name="${new_name}_"
            new_name="${new_name}${round_name}"
        fi
        
        if [[ -n "$court_name" ]]; then
            [[ -n "$new_name" ]] && new_name="${new_name}_"
            new_name="${new_name}${court_name}"
        fi
        
        # Add original name
        [[ -n "$new_name" ]] && new_name="${new_name}_"
        new_name="${new_name}${base_name}.${extension}"
        
        # Skip if no change needed
        if [[ "$original_name" == "$new_name" ]]; then
            continue
        fi
        
        local new_path="$split_dir/$new_name"
        
        # Skip if target file already exists
        if [[ -f "$new_path" ]]; then
            log_warning "Target file already exists: $new_name"
            continue
        fi
        
        log_info "Renaming: $original_name -> $new_name"
        mv "$video_file" "$new_path"
        ((count++))
    done
    
    if [[ $count -gt 0 ]]; then
        log_success "Renamed $count video files"
    else
        log_info "No files needed renaming"
    fi
}

# Mode selection function
select_processing_mode() {
    echo ""
    log_info "GoPro Video Processing Workflow"
    echo ""
    echo "There are two main ways to process your GoPro videos:"
    echo ""
    echo "1. INDIVIDUAL MATCH MODE"
    echo "   • Each processed video represents one complete match"
    echo "   • Videos already contain team names, round, and court information"
    echo "   • Best for: Pre-split videos, individual game recordings"
    echo ""
    echo "2. TOURNAMENT RECORDING MODE" 
    echo "   • One or more videos contain the entire tournament duration"
    echo "   • Uses match time information to separate and label videos"
    echo "   • Best for: Continuous tournament recordings, long session videos"
    echo ""
    
    while true; do
        read -p "Which processing mode would you like to use? (1 or 2): " mode_choice
        case $mode_choice in
            1)
                PROCESSING_MODE="individual"
                log_info "Selected: Individual Match Mode"
                break
                ;;
            2)
                PROCESSING_MODE="tournament"
                log_info "Selected: Tournament Recording Mode"
                break
                ;;
            *)
                log_warning "Please enter 1 or 2"
                ;;
        esac
    done
    echo ""
}

# Individual match processing workflow
run_individual_match_workflow() {
    local video_dir="$1"
    
    log_info "Starting Individual Match Mode processing"
    log_info "Input directory: $video_dir"
    
    # Step 1: Fix directory names
    fix_directory_names "$video_dir"
    
    # Step 2: Identify and organize individual match videos
    log_info "Scanning for individual match videos..."
    
    # Look for video files in the directory
    local video_count=0
    for ext in MP4 mp4 MOV mov AVI avi; do
        for video_file in "$video_dir"/*.$ext; do
            [[ -f "$video_file" ]] && ((video_count++))
        done
    done
    
    if [[ $video_count -eq 0 ]]; then
        log_error "No video files found in $video_dir"
        exit 1
    fi
    
    log_info "Found $video_count video file(s)"
    
    # Step 3: Process each video as an individual match
    echo ""
    log_info "Processing individual match videos..."
    echo "For each video, you'll be asked to provide match information."
    echo ""
    
    local processed_count=0
    for ext in MP4 mp4 MOV mov AVI avi; do
        for video_file in "$video_dir"/*.$ext; do
            [[ -f "$video_file" ]] || continue
            
            local video_name=$(basename "$video_file")
            echo "----------------------------------------"
            log_info "Processing: $video_name"
            
            # Get match information from user
            get_match_info_for_video "$video_file"
            
            ((processed_count++))
        done
    done
    
    log_success "Processed $processed_count individual match videos"
}

# Tournament recording processing workflow  
run_tournament_recording_workflow() {
    local video_dir="$1"
    
    log_info "Starting Tournament Recording Mode processing"
    log_info "Input directory: $video_dir"
    
    # Step 1: Fix directory names
    fix_directory_names "$video_dir"
    
    # Step 2: Prepare games JSONL with match timing information
    prepare_games_jsonl "$video_dir"
    local jsonl_file="$video_dir/games.jsonl"
    
    if [[ ! -f "$jsonl_file" ]]; then
        log_error "Games JSONL file not found. Cannot proceed with tournament recording mode."
        log_info "You'll need to create a games.jsonl file with match timing information."
        log_info "Run: $SCRIPT_DIR/generate_games_template.sh to create a template."
        exit 1
    fi
    
    # Step 3: Combine GoPro videos if needed
    log_info "Combining GoPro videos..."
    "$SCRIPT_DIR/combine_gopro_videos.sh" "$video_dir"
    
    if [[ $? -ne 0 ]]; then
        log_error "Failed to combine GoPro videos"
        exit 1
    fi
    
    log_success "GoPro videos combined successfully"
    
    # Step 4: Split videos based on match timing from JSONL
    local merged_dir="$video_dir/merged_videos"
    local split_dir="$video_dir/split_videos"
    
    log_info "Splitting videos into individual games using match timing..."
    
    # Process each merged video
    for merged_video in "$merged_dir"/*.MP4; do
        [[ -f "$merged_video" ]] || continue
        
        log_info "Processing: $(basename "$merged_video")"
        "$SCRIPT_DIR/split_game_videos.sh" "$merged_video" "$jsonl_file"
        
        if [[ $? -ne 0 ]]; then
            log_error "Failed to split video: $merged_video"
            exit 1
        fi
    done
    
    log_success "Videos split successfully using match timing"
}

# Get match information for individual video
get_match_info_for_video() {
    local video_file="$1"
    local video_basename=$(basename "$video_file" | sed 's/\.[^.]*$//')
    
    echo ""
    echo "Match Information for: $(basename "$video_file")"
    echo "Please provide the following details:"
    
    # Get team names
    read -p "Home team name: " home_team
    read -p "Away team name: " away_team
    
    # Get match details
    read -p "Tournament name [$DEFAULT_TOURNAMENT_NAME]: " tournament_name
    tournament_name=${tournament_name:-$DEFAULT_TOURNAMENT_NAME}
    
    read -p "Court name [$DEFAULT_COURT_NAME]: " court_name  
    court_name=${court_name:-$DEFAULT_COURT_NAME}
    
    read -p "Round name [$DEFAULT_ROUND_NAME]: " round_name
    round_name=${round_name:-$DEFAULT_ROUND_NAME}
    
    # Optional: Get scores
    read -p "Home team score (optional): " home_score
    read -p "Away team score (optional): " away_score
    
    # Create formatted filename
    local formatted_name=$(format_match_filename "$home_team" "$away_team" "$tournament_name" "$court_name" "$round_name")
    
    # Copy/rename the video file
    local output_dir="$video_dir/processed_matches"
    mkdir -p "$output_dir"
    
    local output_file="$output_dir/${formatted_name}.mp4"
    
    log_info "Saving as: $(basename "$output_file")"
    cp "$video_file" "$output_file"
    
    if [[ $? -eq 0 ]]; then
        log_success "Successfully processed match video"
    else
        log_error "Failed to process match video"
    fi
    
    echo ""
}

# Format match filename
format_match_filename() {
    local home_team="$1"
    local away_team="$2" 
    local tournament="$3"
    local court="$4"
    local round="$5"
    
    # Clean and format team names
    local clean_home=$(echo "$home_team" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9]/_/g' | sed 's/_*$//' | sed 's/^_*//')
    local clean_away=$(echo "$away_team" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9]/_/g' | sed 's/_*$//' | sed 's/^_*//')
    local clean_tournament=$(echo "$tournament" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9]/_/g' | sed 's/_*$//' | sed 's/^_*//')
    local clean_court=$(echo "$court" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9]/_/g' | sed 's/_*$//' | sed 's/^_*//')
    local clean_round=$(echo "$round" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9]/_/g' | sed 's/_*$//' | sed 's/^_*//')
    
    echo "${clean_home}_vs_${clean_away}_${clean_tournament}_${clean_court}_${clean_round}"
}

# Main workflow function
run_workflow() {
    local video_dir="$1"
    
    # Validate input directory
    if [[ ! -d "$video_dir" ]]; then
        log_error "Directory not found: $video_dir"
        exit 1
    fi
    
    # Select processing mode
    select_processing_mode
    
    # Run appropriate workflow based on mode
    case $PROCESSING_MODE in
        "individual")
            run_individual_match_workflow "$video_dir"
            ;;
        "tournament")
            run_tournament_recording_workflow "$video_dir"
            ;;
        *)
            log_error "Invalid processing mode: $PROCESSING_MODE"
            exit 1
            ;;
    esac
    
    # Final steps common to both modes
    log_info "Cleaning up temporary files..."
    
    if [[ "$CLEANUP_INTERMEDIATE_FILES" == "true" ]]; then
        # Clean up intermediate files if configured
        log_info "Removing intermediate files..."
        # Add cleanup logic here if needed
    fi
    
    log_success "GoPro video processing workflow completed!"
    echo ""
    echo "Processed videos can be found in:"
    if [[ "$PROCESSING_MODE" == "individual" ]]; then
        echo "  $video_dir/processed_matches/"
    else
        echo "  $video_dir/split_videos/"
    fi
    echo ""
}

# Usage information
show_usage() {
    cat << EOF
Usage: $0 [OPTIONS] <video_directory>

GoPro Video Processing Workflow

This script automates GoPro video processing with two modes:

1. INDIVIDUAL MATCH MODE: Each video is one complete match
2. TOURNAMENT RECORDING MODE: Long videos split using match timing

The script will guide you through selecting the appropriate mode.

OPTIONS:
    -h, --help      Show this help message  
    -v, --version   Show version information
    -c, --config    Specify config file path

EXAMPLES:
    $0 /path/to/gopro/videos
    $0 -c /path/to/custom/config.conf /path/to/videos

For Individual Match Mode:
    • Use when each video file represents one complete match
    • Script will ask for team names, tournament, court, and round info
    
For Tournament Recording Mode:  
    • Use when you have long recordings that need to be split
    • Requires a games.jsonl file with match timing information
    • Use generate_games_template.sh to create the timing template

EOF
}

# Parse command line arguments
parse_args() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            -h|--help)
                show_help
                exit 0
                ;;
            -v|--version)
                show_version
                exit 0
                ;;
            -c|--config)
                CONFIG_FILE="$2"
                shift 2
                ;;
            *)
                VIDEO_DIR="$1"
                shift
                ;;
        esac
    done
}

# Main execution
parse_args "$@"

if [[ -z "$VIDEO_DIR" ]]; then
    show_usage
    exit 1
fi

# Load configuration and run workflow
load_config
create_config
run_workflow "$VIDEO_DIR"
