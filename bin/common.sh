#!/bin/bash

# GoPro Video Tools - Shared Version and Utilities
# Source this file in other scripts to get common functions

# Version info
GOPRO_TOOLS_VERSION="1.0.0"
GOPRO_TOOLS_NAME="GoPro Video Tools"
GOPRO_TOOLS_AUTHOR="Jessica Sartin"
GOPRO_TOOLS_YEAR="2025"

# Get version from VERSION file if it exists
get_version() {
    local script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    local version_file="$script_dir/../VERSION"
    
    if [[ -f "$version_file" ]]; then
        cat "$version_file" | tr -d '\n\r'
    else
        echo "$GOPRO_TOOLS_VERSION"
    fi
}

# Show version info
show_version_info() {
    local script_name="${1:-$GOPRO_TOOLS_NAME}"
    local version=$(get_version)
    echo "$script_name v$version"
    echo "Copyright (c) $GOPRO_TOOLS_YEAR $GOPRO_TOOLS_AUTHOR"
}

# Common colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Common logging functions
log_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
log_warning() { echo -e "${YELLOW}[WARNING]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }
