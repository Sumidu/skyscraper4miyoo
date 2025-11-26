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
    local output_path="${ARTWORK_OUTPUT_PATH:-${ROM_BASE_PATH}/${folder_name}/Imgs}"
    
    if [[ ! -d "$rom_path" ]]; then
        echo "  Skipping $platform - directory not found at $rom_path"
        return 0
    fi
    
    echo "Generating artwork for $platform..."
    
    # Create output directory if it doesn't exist
    mkdir -p "$output_path"
    
    # Build Skyscraper command using array
    local cmd=("Skyscraper" "-p" "$platform" "-i" "$rom_path" "-o" "$output_path")
    
    # Add cache path if specified
    if [[ -n "$CACHE_PATH" ]]; then
        cmd+=("-d" "$CACHE_PATH")
    fi
    
    # Build flags list
    local flags=""
    
    # Note: Image dimensions (IMAGE_WIDTH/IMAGE_HEIGHT) should be set in the artwork XML file
    # via the <output> tag's width and height attributes, not via command line flags.
    # See artwork/*.xml for examples.
    
    # Add skip existing flags for media types
    if [[ "$SKIP_EXISTING" == "true" ]]; then
        flags="skipexistingscreenshots,skipexistingcovers,skipexistingwheels,skipexistingmarquees"
    fi
    
    # Add unattend flag for non-interactive mode
    if [[ "$UNATTENDED" == "true" ]]; then
        if [[ -n "$flags" ]]; then
            flags+=",unattend"
        else
            flags="unattend"
        fi
    fi
    
    # Add combined flags if any
    if [[ -n "$flags" ]]; then
        cmd+=("--flags" "$flags")
    fi
    
    # Log command
    echo "Running: Skyscraper -p $platform -i \"$rom_path\" -o \"$output_path\"..."
    
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
    echo "  Output: ${ARTWORK_OUTPUT_PATH:-<platform>/Imgs}"
    echo "  Dimensions: ${IMAGE_WIDTH}x${IMAGE_HEIGHT}"
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
