# GoPro Video Tools

A standalone bash toolkit for automating GoPro tournament video processing, including merging, splitting, renaming, and metadata management.

## Features

- **Batch Rename Videos**: Standardize filenames with tournament metadata
- **Combine GoPro Videos**: Merge multiple GoPro files into single game videos
- **Split Game Videos**: Automatically split long recordings into individual games
- **Tournament Workflow**: End-to-end processing pipeline
- **Template Generation**: Create tournament bracket templates

## Installation

### Prerequisites
- bash (4.0+)
- ffmpeg
- Basic command line tools (grep, sed, awk)

### Quick Install
Run the installation script to install all dependencies:

```bash
./bin/install.sh
```

### Manual Installation
See `bin/install.sh` for manual dependency installation instructions.

## Usage

### Configuration
1. Copy and edit the configuration file:
```bash
cp config/gopro_config.conf config/my_tournament.conf
# Edit the configuration values
```

2. Use the main workflow script:
```bash
./bin/gopro_workflow.sh
```

### Individual Scripts
- `./bin/batch_rename_videos.sh` - Rename videos with metadata
- `./bin/combine_gopro_videos.sh` - Merge GoPro video files
- `./bin/split_game_videos.sh` - Split recordings into games
- `./bin/generate_games_template.sh` - Create tournament templates

## Directory Structure
```
gopro-video-tools/
├── bin/           # Executable scripts
├── config/        # Configuration files
└── static/        # Static assets (logos, etc.)
```
