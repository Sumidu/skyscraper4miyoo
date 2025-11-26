#!/bin/bash
# =============================================================================
# Skyscraper Artwork Generation Script for Miyoo Mini
# =============================================================================
# This script generates final artwork from cached scraper data.
# Run this after scrape.sh to compile game images.
# =============================================================================

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_FILE="${SCRIPT_DIR}/config.cfg"
UTILS_FILE="${SCRIPT_DIR}/utils.sh"

# Load configuration
# shellcheck source=config.cfg
if [[ -f "$CONFIG_FILE" ]]; then
    source "$CONFIG_FILE"
else
    echo "Error: Configuration file not found at $CONFIG_FILE"
    echo "Please create config.cfg based on the provided template."
    exit 1
fi

# Load utility functions
# shellcheck source=utils.sh
if [[ -f "$UTILS_FILE" ]]; then
    source "$UTILS_FILE"
else
    echo "Error: Utility file not found at $UTILS_FILE"
    exit 1
fi

# Validate required settings
validate_config() {
    local missing=""
    
    if [[ -z "$ROM_BASE_PATH" ]]; then
        missing+="  - ROM_BASE_PATH\n"
    fi
    
    if [[ -n "$missing" ]]; then
        echo "Error: Missing required configuration:"
        echo -e "$missing"
        exit 1
    fi
    
    if [[ ! -d "$ROM_BASE_PATH" ]]; then
        echo "Error: ROM_BASE_PATH does not exist: $ROM_BASE_PATH"
        exit 1
    fi
}

# Check if Skyscraper is installed
check_skyscraper() {
    if ! command -v Skyscraper &> /dev/null; then
        echo "Error: Skyscraper is not installed or not in PATH"
        echo "Please install Skyscraper:"
        echo "  macOS: brew install skyscraper"
        echo "  Linux: See https://github.com/Gemba/skyscraper"
        exit 1
    fi
    echo "Skyscraper found: $(which Skyscraper)"
}

# Generate artwork for a single platform
generate_artwork_platform() {
    local platform="$1"
    local folder_name
    folder_name=$(get_platform_folder "$platform")
    local rom_path="${ROM_BASE_PATH}/${folder_name}"
    # Output directly to Imgs folder within the platform directory
    local output_path="${ROM_BASE_PATH}/${folder_name}/Imgs"
    local gamelist_path="${ROM_BASE_PATH}/${folder_name}"
    
    if [[ ! -d "$rom_path" ]]; then
        echo "  Skipping $platform - directory not found at $rom_path"
        return 0
    fi
    
    echo "Generating artwork for $platform..."
    
    # Create output directory if it doesn't exist
    mkdir -p "$output_path"
    
    # Build Skyscraper command using array
    # The gamelist is placed in the ROM directory while images go to Imgs subfolder
    local cmd=("Skyscraper" "-p" "$platform" "-i" "$rom_path" "-o" "$output_path" "-g" "$gamelist_path")
    
    # Add artwork XML file if specified
    if [[ -n "$ARTWORK_XML" ]] && [[ -f "$ARTWORK_XML" ]]; then
        cmd+=("-a" "$ARTWORK_XML")
    fi
    
    # Add cache path if specified
    if [[ -n "$CACHE_PATH" ]]; then
        cmd+=("-d" "$CACHE_PATH")
    fi
    
    # Build flags list - use unattendskip for combined unattended mode with skip functionality
    local flags="unattendskip"
    
    # Add combined flags
    cmd+=("--flags" "$flags")
    
    # Log command
    local artwork_info=""
    if [[ -n "$ARTWORK_XML" ]]; then
        artwork_info=" -a \"$ARTWORK_XML\""
    fi
    echo "Running: Skyscraper -p $platform -i \"$rom_path\" -o \"$output_path\" -g \"$gamelist_path\"${artwork_info}..."
    
    # Execute artwork generation
    "${cmd[@]}"
    
    echo "Completed artwork generation for $platform"
    echo ""
}

# Main artwork generation function
main() {
    echo "=========================================="
    echo "Skyscraper Artwork Generator for Miyoo Mini"
    echo "=========================================="
    echo ""
    
    validate_config
    check_skyscraper
    
    echo ""
    echo "Configuration:"
    echo "  ROM Path: $ROM_BASE_PATH"
    echo "  Output: <platform>/Imgs"
    if [[ -n "$ARTWORK_XML" ]]; then
        echo "  Artwork XML: $ARTWORK_XML"
    fi
    echo "  Platforms: $PLATFORMS"
    echo ""
    
    # Check if specific platform was provided as argument
    if [[ -n "$1" ]]; then
        echo "Generating artwork for single platform: $1"
        generate_artwork_platform "$1"
    else
        echo "Generating artwork for all configured platforms..."
        echo ""
        
        for platform in $PLATFORMS; do
            generate_artwork_platform "$platform"
        done
    fi
    
    echo ""
    echo "=========================================="
    echo "Artwork generation complete!"
    echo "Copy the generated images to your Miyoo Mini."
    echo "=========================================="
}

main "$@"
