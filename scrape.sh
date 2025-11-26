#!/bin/bash
# =============================================================================
# Skyscraper Scraping Script for Miyoo Mini
# =============================================================================
# This script scrapes game metadata and artwork from online sources
# and caches them locally for later artwork generation.
# =============================================================================

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_FILE="${SCRIPT_DIR}/config.cfg"

# Load configuration
# shellcheck source=config.cfg
if [[ -f "$CONFIG_FILE" ]]; then
    source "$CONFIG_FILE"
else
    echo "Error: Configuration file not found at $CONFIG_FILE"
    echo "Please create config.cfg based on the provided template."
    exit 1
fi

# Validate required settings
validate_config() {
    local missing=""
    
    if [[ -z "$ROM_BASE_PATH" ]]; then
        missing+="  - ROM_BASE_PATH\n"
    fi
    
    if [[ -z "$SCRAPE_SOURCE" ]]; then
        missing+="  - SCRAPE_SOURCE\n"
    fi
    
    if [[ "$SCRAPE_SOURCE" == "screenscraper" ]]; then
        if [[ -z "$SCREENSCRAPER_USER" ]] || [[ -z "$SCREENSCRAPER_PASS" ]]; then
            missing+="  - SCREENSCRAPER_USER and SCREENSCRAPER_PASS (required for screenscraper source)\n"
        fi
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

# Scrape a single platform
scrape_platform() {
    local platform="$1"
    local rom_path="${ROM_BASE_PATH}/${platform}"
    
    # Convert platform name to directory if different naming convention
    # Miyoo Mini often uses uppercase folder names
    if [[ ! -d "$rom_path" ]]; then
        # Try uppercase version
        local upper_platform
        upper_platform=$(echo "$platform" | tr '[:lower:]' '[:upper:]')
        rom_path="${ROM_BASE_PATH}/${upper_platform}"
    fi
    
    if [[ ! -d "$rom_path" ]]; then
        echo "  Skipping $platform - directory not found"
        return 0
    fi
    
    echo "Scraping $platform from $rom_path..."
    
    # Build Skyscraper command using array
    local cmd=("Skyscraper" "-p" "$platform" "-s" "$SCRAPE_SOURCE" "-i" "$rom_path")
    
    # Add credentials for screenscraper (not logged for security)
    if [[ "$SCRAPE_SOURCE" == "screenscraper" ]] && [[ -n "$SCREENSCRAPER_USER" ]]; then
        cmd+=("-u" "${SCREENSCRAPER_USER}:${SCREENSCRAPER_PASS}")
    fi
    
    # Add cache path if specified
    if [[ -n "$CACHE_PATH" ]]; then
        cmd+=("-d" "$CACHE_PATH")
    fi
    
    # Add threading
    if [[ -n "$MAX_THREADS" ]]; then
        cmd+=("-t" "$MAX_THREADS")
    fi
    
    # Add verbosity
    if [[ "$VERBOSITY" -eq 2 ]]; then
        cmd+=("--verbosity" "3")
    fi
    
    # Add unattended mode
    if [[ "$UNATTENDED" == "true" ]]; then
        cmd+=("--unattended")
    fi
    
    # Log command without credentials for security
    echo "Running: Skyscraper -p $platform -s $SCRAPE_SOURCE -i \"$rom_path\"..."
    
    # Execute scraping
    "${cmd[@]}"
    
    echo "Completed scraping $platform"
    echo ""
}

# Main scraping function
main() {
    echo "=========================================="
    echo "Skyscraper ROM Scraper for Miyoo Mini"
    echo "=========================================="
    echo ""
    
    validate_config
    check_skyscraper
    
    echo ""
    echo "Configuration:"
    echo "  ROM Path: $ROM_BASE_PATH"
    echo "  Source: $SCRAPE_SOURCE"
    echo "  Platforms: $PLATFORMS"
    echo ""
    
    # Check if specific platform was provided as argument
    if [[ -n "$1" ]]; then
        echo "Scraping single platform: $1"
        scrape_platform "$1"
    else
        echo "Scraping all configured platforms..."
        echo ""
        
        for platform in $PLATFORMS; do
            scrape_platform "$platform"
        done
    fi
    
    echo ""
    echo "=========================================="
    echo "Scraping complete!"
    echo "Run ./generate_artwork.sh to generate game artwork"
    echo "=========================================="
}

main "$@"
