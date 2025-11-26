#!/bin/bash
#
# scrape.sh - Main scraping script for Miyoo Mini
#
# A script to scrape game artwork for Miyoo Mini using Skyscraper.
# This script runs on macOS and helps gather game screenshots, covers,
# and other media for your ROM collection.
#
# Usage: ./scrape.sh [OPTIONS] [SYSTEMS]
#

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# PROJECT_DIR is available for future use or can be used in sourced configs
export PROJECT_DIR
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

# Default configuration
CONFIG_FILE="${HOME}/.config/skyscraper4miyoo/config"
SKYSCRAPER_INI="${HOME}/.skyscraper/config.ini"
MODULE="screenscraper"
GAMELIST="true"
EXCLUDE=(PORTS PICO)

# Load user configuration if it exists
if [[ -f "$CONFIG_FILE" ]]; then
    # shellcheck source=/dev/null
    source "$CONFIG_FILE"
elif [[ -f "${HOME}/.skyscraper4miyoo.conf" ]]; then
    # shellcheck source=/dev/null
    source "${HOME}/.skyscraper4miyoo.conf"
fi

# Miyoo Mini system to Skyscraper platform mapping
declare -A SYSTEM_MAP
SYSTEM_MAP[AMIGA]=amiga
SYSTEM_MAP[CPC]=amstradcpc
SYSTEM_MAP[ARCADE]=mame-libretro
SYSTEM_MAP[ATARI]=atari2600
SYSTEM_MAP[FIFTYTWOHUNDRED]=atari5200
SYSTEM_MAP[SEVENTYEIGHTHUNDRED]=atari7800
SYSTEM_MAP[LYNX]=atarilynx
SYSTEM_MAP[WS]="wonderswan wonderswancolor"
SYSTEM_MAP[COLECO]=coleco
SYSTEM_MAP[VECTREX]=vectrex
SYSTEM_MAP[INTELLIVISION]=intellivision
SYSTEM_MAP[MSX]=msx
SYSTEM_MAP[PCECD]=pcenginecd
SYSTEM_MAP[PCE]=pcengine
SYSTEM_MAP[FC]=nes
SYSTEM_MAP[GB]="gb gbc"
SYSTEM_MAP[GBC]=gbc
SYSTEM_MAP[GBA]=gba
SYSTEM_MAP[POKE]=pokemini
SYSTEM_MAP[SFC]=snes
SYSTEM_MAP[VB]=virtualboy
SYSTEM_MAP[PICO]=pico8
SYSTEM_MAP[PORTS]=ports
SYSTEM_MAP[SCUMMVM]=scummvm
SYSTEM_MAP[THIRTYTWOX]=sega32x
SYSTEM_MAP[SEGACD]=segacd
SYSTEM_MAP[GG]=gamegear
SYSTEM_MAP[MD]=megadrive
SYSTEM_MAP[MS]=mastersystem
SYSTEM_MAP[SEGASGONE]=sg-1000
SYSTEM_MAP[ZXS]=zxspectrum
SYSTEM_MAP[NEOGEO]=neogeo
SYSTEM_MAP[NEOCD]=neogeocd
SYSTEM_MAP[NGP]="ngp ngpc"
SYSTEM_MAP[PS]=psx
SYSTEM_MAP[VIDEOPAC]=videopac
SYSTEM_MAP[ARDUBOY]=arduboy
SYSTEM_MAP[EASYRPG]=easyrpg
SYSTEM_MAP[OPENBOR]=openbor

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

function usage() {
    echo "Usage: $(basename "$0") [OPTIONS] [SYSTEMS]"
    echo ""
    echo "Scrape artwork for ROMs on Miyoo Mini using Skyscraper."
    echo ""
    echo "Options:"
    echo "  -a, --all        Scrape all platforms instead of just new ROMs"
    echo "  -c, --clean      Remove artwork for deleted games"
    echo "  -p, --pretend    With --clean, show what would be deleted without deleting"
    echo "  -i, --import     Import manually added assets"
    echo "  -s, --skip       Skip existing output files"
    echo "  -r, --region <r> Override the default region (e.g., us, eu, jp)"
    echo "  -m, --module <m> Scraping module (default: screenscraper)"
    echo "  -g, --game <g>   Process only a specific game file"
    echo "  -h, --help       Show this help message"
    echo ""
    echo "Systems:"
    echo "  Provide system names as arguments (e.g., GBA SFC FC)"
    echo "  If no systems specified, scans for new ROMs since last run"
    echo ""
    echo "Examples:"
    echo "  $(basename "$0")              # Scrape new ROMs"
    echo "  $(basename "$0") --all        # Scrape all systems"
    echo "  $(basename "$0") GBA SFC      # Scrape specific systems"
    echo "  $(basename "$0") --clean      # Remove orphaned artwork"
    echo ""
    echo "Configuration:"
    echo "  Create ~/.config/skyscraper4miyoo/config to customize settings"
    echo "  See config/config.example for available options"
    exit 0
}

function log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

function log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

function log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

function log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

function check_dependencies() {
    local missing=()
    
    if ! command -v Skyscraper &> /dev/null; then
        missing+=("Skyscraper")
    fi
    
    if [[ ${#missing[@]} -gt 0 ]]; then
        log_error "Missing required dependencies: ${missing[*]}"
        echo ""
        echo "Please install Skyscraper first. See docs/INSTALL.md for instructions."
        exit 1
    fi
}

function check_config() {
    if [[ ! -f "$SKYSCRAPER_INI" ]]; then
        log_error "Skyscraper config not found at: $SKYSCRAPER_INI"
        echo ""
        echo "Please run: ./scripts/setup.sh to configure the project"
        exit 1
    fi
}

function get_rom_path() {
    local input_line
    input_line=$(grep -m 1 "^inputFolder" "$SKYSCRAPER_INI" 2>/dev/null || echo "")
    if [[ -z "$input_line" ]]; then
        log_error "Could not find inputFolder in Skyscraper config"
        exit 1
    fi
    
    local rom_path="${input_line##*=}"
    rom_path="${rom_path%\"}"
    rom_path="${rom_path#\"}"
    echo "$rom_path"
}

function check_rom_path() {
    local rom_path="$1"
    
    if [[ ! -d "$rom_path" ]]; then
        log_error "ROM path does not exist: $rom_path"
        echo "Please check your Skyscraper configuration."
        exit 1
    fi
    
    if [[ -z "$(ls -A "$rom_path" 2>/dev/null)" ]]; then
        log_warning "ROM path is empty: $rom_path"
    fi
}

function scrape_platform() {
    local system="$1"
    local platform="$2"
    local rom_path="$3"
    local skip_in="$4"
    local skip_out="$5"
    local region_opt="$6"
    local game_file="$7"
    
    log_info "Scraping $system (Skyscraper platform: $platform)"
    
    local system_path="$rom_path/$system"
    
    if [[ ! -d "$system_path" ]]; then
        log_warning "System folder does not exist: $system_path"
        return
    fi
    
    if [[ -z "$(ls -A "$system_path" 2>/dev/null)" ]]; then
        log_warning "No games found in: $system_path"
        return
    fi
    
    # Scrape from source
    if [[ -n "$game_file" ]]; then
        Skyscraper -c "$SKYSCRAPER_INI" -p "$platform" -s "$MODULE" \
            -i "$system_path" \
            --flags "$skip_in" \
            ${region_opt:+"$region_opt"} "$game_file" || true
    else
        Skyscraper -c "$SKYSCRAPER_INI" -p "$platform" -s "$MODULE" \
            -i "$system_path" \
            --flags "$skip_in" \
            ${region_opt:+"$region_opt"} || true
    fi
    
    # Generate artwork
    Skyscraper -c "$SKYSCRAPER_INI" -p "$platform" \
        -i "$system_path" -o "$system_path/Imgs" \
        --flags "$skip_out" || true
    
    # Move screenshots to Imgs folder (Miyoo Mini convention)
    if [[ -d "$system_path/Imgs/screenshots" ]]; then
        mv "$system_path/Imgs/screenshots/"* "$system_path/Imgs/" 2>/dev/null || true
        rmdir "$system_path/Imgs/screenshots" 2>/dev/null || true
    fi
    
    # Clean up empty folders
    for folder in covers marquees textures wheels; do
        rmdir "$system_path/Imgs/$folder" 2>/dev/null || true
    done
    
    # Handle game list
    if [[ "$GAMELIST" == "true" && -f "$system_path/gamelist.xml" ]]; then
        # Fix image paths
        if [[ "$OSTYPE" == "darwin"* ]]; then
            sed -i '' 's|Imgs/screenshots|Imgs|g' "$system_path/gamelist.xml"
        else
            sed -i 's|Imgs/screenshots|Imgs|g' "$system_path/gamelist.xml"
        fi
        
        # Rename to miyoogamelist.xml
        mv "$system_path/gamelist.xml" "$system_path/miyoogamelist.$platform.xml"
    else
        rm -f "$system_path/gamelist.xml"
    fi
    
    log_success "Finished scraping $system"
}

function clean_assets() {
    local rom_path="$1"
    local systems="$2"
    local dry_run="$3"
    
    log_info "Cleaning orphaned artwork..."
    
    for system_dir in "$rom_path"/*/; do
        local system
        system=$(basename "$system_dir")
        
        # Skip if systems list provided and this system is not in it
        if [[ -n "$systems" ]] && [[ ! " $systems " =~ \ $system\  ]]; then
            continue
        fi
        
        # Skip excluded systems
        local skip=false
        for excluded in "${EXCLUDE[@]}"; do
            if [[ "$excluded" == "$system" ]]; then
                skip=true
                break
            fi
        done
        
        if $skip; then
            continue
        fi
        
        local imgs_dir="$system_dir/Imgs"
        if [[ ! -d "$imgs_dir" ]]; then
            continue
        fi
        
        log_info "Checking $system..."
        
        for artwork in "$imgs_dir"/*; do
            if [[ ! -f "$artwork" ]]; then
                continue
            fi
            
            local game_name
            game_name=$(basename "$artwork")
            game_name="${game_name%.*}"
            
            # Check if corresponding ROM exists
            local rom_count
            rom_count=$(find "$system_dir" -maxdepth 1 -name "${game_name}.*" 2>/dev/null | wc -l)
            
            if [[ "$rom_count" -eq 0 ]]; then
                if [[ "$dry_run" == "true" ]]; then
                    echo "Would delete: $artwork"
                else
                    echo "Deleting: $artwork"
                    rm "$artwork"
                fi
            fi
        done
    done
    
    log_success "Cleanup complete"
}

function merge_gamelists() {
    local system_path="$1"
    local system="$2"
    
    if ! ls "$system_path"/miyoogamelist.*.xml &>/dev/null; then
        return
    fi
    
    local gamelist="$system_path/miyoogamelist.xml"
    
    echo '<?xml version="1.0"?>' > "$gamelist"
    echo '<gameList>' >> "$gamelist"
    
    for partial in "$system_path"/miyoogamelist.*.xml; do
        # Extract game entries and append
        if command -v xmlstarlet &>/dev/null; then
            xmlstarlet sel -t --copy-of '//gameList/game' "$partial" >> "$gamelist"
        else
            # Fallback: remove XML header and gameList tags
            tail -n +3 "$partial" | head -n -1 >> "$gamelist"
        fi
    done
    
    echo '</gameList>' >> "$gamelist"
    
    # Clean up partial files
    rm -f "$system_path"/miyoogamelist.*.xml
}

# Main script
check_dependencies

# Parse arguments
ALL_PLATFORMS=false
SKIP_IN="unattendskip"
SKIP_OUT="unattend"
CLEAN=false
DRY_RUN=false
REGION=""
GAME=""
SYSTEMS=""

while [[ "$1" == "-"* ]]; do
    case "$1" in
        -h|--help)
            usage
            ;;
        -a|--all)
            ALL_PLATFORMS=true
            shift
            ;;
        -c|--clean)
            CLEAN=true
            shift
            ;;
        -p|--pretend)
            DRY_RUN=true
            shift
            ;;
        -i|--import)
            # Set module to import and adjust flags
            MODULE="import"
            SKIP_IN="unattend"
            shift
            ;;
        -s|--skip)
            SKIP_OUT="unattendskip"
            shift
            ;;
        -r|--region)
            REGION="--region $2"
            shift 2
            ;;
        -m|--module)
            MODULE="$2"
            shift 2
            ;;
        -g|--game)
            GAME="$2"
            shift 2
            ;;
        *)
            log_warning "Unknown option: $1"
            shift
            ;;
    esac
done

# Remaining arguments are systems
SYSTEMS="$*"

check_config
ROM_PATH=$(get_rom_path)
check_rom_path "$ROM_PATH"

LASTRUN="$ROM_PATH/.skyscraper4miyoo.lastrun"

# Handle clean mode
if [[ "$CLEAN" == "true" ]]; then
    clean_assets "$ROM_PATH" "$SYSTEMS" "$DRY_RUN"
    exit 0
fi

# Clear lastrun if scraping all
if [[ "$ALL_PLATFORMS" == "true" ]]; then
    rm -f "$LASTRUN"
fi

# Determine which systems to scrape
if [[ -z "$SYSTEMS" ]]; then
    if [[ ! -f "$LASTRUN" ]] || [[ "$ALL_PLATFORMS" == "true" ]]; then
        log_info "Scanning all systems (this may take a while)..."
        SYSTEMS=$(find "$ROM_PATH" -mindepth 1 -maxdepth 1 -type d -exec basename {} \;)
    else
        log_info "Looking for new ROMs since last run..."
        SYSTEMS=$(find "$ROM_PATH" -mindepth 2 -maxdepth 2 -type f -newer "$LASTRUN" -exec sh -c 'basename "$(dirname "$0")"' {} \; 2>/dev/null | sort -u)
        
        if [[ -z "$SYSTEMS" ]]; then
            log_success "No new games found."
            touch "$LASTRUN"
            exit 0
        fi
    fi
fi

# Process each system
for system in $SYSTEMS; do
    # Skip excluded systems
    skip=false
    for excluded in "${EXCLUDE[@]}"; do
        if [[ "$excluded" == "$system" ]]; then
            log_info "Skipping excluded system: $system"
            skip=true
            break
        fi
    done
    
    if $skip; then
        continue
    fi
    
    platforms="${SYSTEM_MAP[$system]}"
    
    if [[ -z "$platforms" ]]; then
        log_warning "Unsupported system: $system"
        continue
    fi
    
    # Process each platform (some systems map to multiple platforms)
    for platform in $platforms; do
        scrape_platform "$system" "$platform" "$ROM_PATH" "$SKIP_IN" "$SKIP_OUT" "$REGION" "$GAME"
    done
    
    # Merge game lists if needed
    if [[ "$GAMELIST" == "true" ]]; then
        merge_gamelists "$ROM_PATH/$system" "$system"
    fi
done

# Update lastrun timestamp
touch "$LASTRUN"

log_success "Scraping complete!"
