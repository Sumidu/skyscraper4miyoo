#!/bin/bash
# =============================================================================
# Skyscraper Scraping Script for Miyoo Mini
# =============================================================================
# This script scrapes game metadata and artwork from online sources
# and caches them locally for later artwork generation.
# =============================================================================

# 'set -e' causes the script to exit immediately if any command fails (returns non-zero)
# This helps catch errors early instead of continuing with broken data
set -e

# SCRIPT_DIR: Gets the directory where this script is located
#   ${BASH_SOURCE[0]} = the script's filename/path
#   dirname = gets just the directory part
#   cd into it and pwd = prints the absolute directory path
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# Set paths to config and utility files relative to this script's directory
CONFIG_FILE="${SCRIPT_DIR}/config.cfg"
UTILS_FILE="${SCRIPT_DIR}/utils.sh"

# Load configuration file
# The 'source' command reads and executes another shell script in the current shell
# This makes all variables from config.cfg available to this script
# shellcheck source=config.cfg
# [[ -f "$CONFIG_FILE" ]] = check if the config file exists and is a regular file
if [[ -f "$CONFIG_FILE" ]]; then
    source "$CONFIG_FILE"
else
    # If config.cfg doesn't exist, show an error and exit with code 1 (failure)
    echo "Error: Configuration file not found at $CONFIG_FILE"
    echo "Please create config.cfg based on the provided template."
    # 'exit 1' stops the script and signals failure to the shell
    exit 1
fi

# Load utility functions (same process as config file)
# shellcheck source=utils.sh
if [[ -f "$UTILS_FILE" ]]; then
    source "$UTILS_FILE"
else
    echo "Error: Utility file not found at $UTILS_FILE"
    # Exit code 1 = script failed
    exit 1
fi

# Function: Validate required settings before running the scraper
# Functions in bash start with 'function_name() {' and end with '}'
# This function checks that all required configuration values are set
validate_config() {
    # 'local' keyword = variable only exists within this function (good practice)
    # Will store any missing required settings
    local missing=""
    
    # Check if ROM_BASE_PATH is empty: -z = "zero length" (true if string is empty)
    if [[ -z "$ROM_BASE_PATH" ]]; then
        # Append error message: += concatenates to the variable
        # \n = newline character for formatting
        missing+="  - ROM_BASE_PATH\n"
    fi
    
    # Check if SCRAPE_SOURCE is set
    if [[ -z "$SCRAPE_SOURCE" ]]; then
        missing+="  - SCRAPE_SOURCE\n"
    fi
    
    # If using screenscraper source, check for username and password
    # == is string comparison (exact match)
    if [[ "$SCRAPE_SOURCE" == "screenscraper" ]]; then
        # -z tests if empty, || means OR, so this checks if EITHER variable is empty
        if [[ -z "$SCREENSCRAPER_USER" ]] || [[ -z "$SCREENSCRAPER_PASS" ]]; then
            missing+="  - SCREENSCRAPER_USER and SCREENSCRAPER_PASS (required for screenscraper source)\n"
        fi
    fi
    
    # If any required settings are missing, display them and exit
    # -n = "not zero length" (true if string is NOT empty)
    if [[ -n "$missing" ]]; then
        echo "Error: Missing required configuration:"
        # echo -e enables interpretation of backslash escapes (like \n for newline)
        echo -e "$missing"
        exit 1
    fi
    
    # Check that the ROM directory actually exists: -d = directory exists
    if [[ ! -d "$ROM_BASE_PATH" ]]; then
        echo "Error: ROM_BASE_PATH does not exist: $ROM_BASE_PATH"
        exit 1
    fi
}

# Function: Check if Skyscraper tool is installed and available
check_skyscraper() {
    # 'command -v' checks if a command/program exists in the system PATH
    # &> /dev/null redirects both stdout and stderr to /dev/null (silent, no output)
    # ! means NOT, so this checks "if command is NOT found"
    if ! command -v Skyscraper &> /dev/null; then
        echo "Error: Skyscraper is not installed or not in PATH"
        echo "Please install Skyscraper:"
        echo "  macOS: brew install skyscraper"
        echo "  Linux: See https://github.com/Gemba/skyscraper"
        exit 1
    fi
    # If we reach here, Skyscraper is found. Show the user where it was found:
    # $(which Skyscraper) = command substitution: runs the command and uses its output
    echo "Skyscraper found: $(which Skyscraper)"
}

# Function: Scrape metadata for a single game platform (e.g., nes, snes, etc.)
# Parameters: $1 = platform name (passed in when function is called)
scrape_platform() {
    # local platform="$1" = take the first argument and store it as a local variable
    # $1 refers to the first argument passed to this function
    local platform="$1"
    # Call a function from utils.sh to get the folder name for this platform
    # The $(function_name) syntax captures the output of a function call
    local folder_name
    folder_name=$(get_platform_folder "$platform")
    # Build the full path to the ROM files for this platform
    local rom_path="${ROM_BASE_PATH}/${folder_name}"
    
    # Check if the directory exists (-d); if not, skip this platform
    if [[ ! -d "$rom_path" ]]; then
        echo "  Skipping $platform - directory not found at $rom_path"
        # 'return 0' exits the function successfully without error
        return 0
    fi
    
    echo "Scraping $platform from $rom_path..."
    
    # Build a command as an array (arrays in bash use parentheses and spaces)
    # This is better than a string because it properly handles spaces in filenames
    # Each element of the array will be passed as a separate argument to Skyscraper
    local cmd=("Skyscraper" "-p" "$platform" "-s" "$SCRAPE_SOURCE" "-i" "$rom_path")
    
    # Add credentials for screenscraper (only if using that source)
    # Note: We don't log this command with credentials visible for security
    if [[ "$SCRAPE_SOURCE" == "screenscraper" ]] && [[ -n "$SCREENSCRAPER_USER" ]]; then
        # += adds new elements to the array
        # The -u flag provides username:password credentials
        cmd+=("-u" "${SCREENSCRAPER_USER}:${SCREENSCRAPER_PASS}")
    fi
    
    # Optionally add custom cache directory if configured
    if [[ -n "$CACHE_PATH" ]]; then
        # -d flag specifies where to store the cache
        cmd+=("-d" "$CACHE_PATH")
    fi
    
    # Optionally enable multi-threading for faster scraping
    if [[ -n "$MAX_THREADS" ]]; then
        # -t flag sets number of threads to use
        cmd+=("-t" "$MAX_THREADS")
    fi
    
    # Optionally increase verbosity (detailed output) for debugging
    if [[ "$VERBOSITY" -eq 2 ]]; then
        # -eq is numeric equality comparison
        # --verbosity 3 gives very detailed output
        cmd+=("--verbosity" "3")
    fi
    
    # Optionally run in unattended mode (no interactive prompts)
    if [[ "$UNATTENDED" == "true" ]]; then
        # --flags unattend runs Skyscraper without user interaction
        cmd+=("--flags" "unattend")
    fi
    
    # Log command without credentials for security
    echo "Running: Skyscraper -p $platform -s $SCRAPE_SOURCE -i \"$rom_path\" ..."
    
    # Execute the scraping command
    # "${cmd[@]}" expands all array elements as separate arguments
    # This is the proper way to execute a command stored in an array
    "${cmd[@]}"
    
    echo "Completed scraping $platform"
    echo ""
}

# Function: Main entry point for the scraper
# This is where the script actually starts executing when you run it
main() {
    # Print a header banner to show what's starting
    echo "=========================================="
    echo "Skyscraper ROM Scraper for Miyoo Mini"
    echo "=========================================="
    echo ""
    
    # Call the validation function to check configuration
    validate_config
    # Call the check function to ensure Skyscraper is installed
    check_skyscraper
    
    echo ""
    echo "Configuration:"
    echo "  ROM Path: $ROM_BASE_PATH"
    echo "  Source: $SCRAPE_SOURCE"
    echo "  Platforms: $PLATFORMS"
    echo ""
    
    # Check if user provided a specific platform as a command-line argument
    # $1 refers to the first argument passed to the script when run from shell
    # -n tests if string is not empty
    if [[ -n "$1" ]]; then
        echo "Scraping single platform: $1"
        # Call scrape_platform function with the platform name
        scrape_platform "$1"
    else
        # If no argument provided, scrape all configured platforms
        echo "Scraping all configured platforms..."
        echo ""
        
        # 'for' loop: iterate through each platform in the PLATFORMS variable
        # The variable PLATFORMS should contain space-separated platform names
        # In each iteration, platform = one platform name
        for platform in $PLATFORMS; do
            # Call the scrape function for each platform
            scrape_platform "$platform"
        done
    fi
    
    # Print completion message
    echo ""
    echo "=========================================="
    echo "Scraping complete!"
    echo "Run ./generate_artwork.sh to generate game artwork"
    echo "=========================================="
}

# Call the main function
# "$@" passes all command-line arguments from the script to the main function
# This allows main() to receive the same arguments the user passed to the script
main "$@"
