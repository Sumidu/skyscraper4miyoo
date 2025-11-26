#!/bin/bash
#
# setup.sh - Setup script for skyscraper4miyoo
#
# This script helps configure Skyscraper for use with Miyoo Mini on macOS.
#

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

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

function check_macos() {
    if [[ "$OSTYPE" != "darwin"* ]]; then
        log_warning "This setup is optimized for macOS. Some features may not work on other systems."
    fi
}

function check_homebrew() {
    if ! command -v brew &> /dev/null; then
        log_error "Homebrew is not installed."
        echo ""
        echo "Please install Homebrew first:"
        # shellcheck disable=SC2016
        echo '  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"'
        exit 1
    fi
    log_success "Homebrew is installed"
}

function install_dependencies() {
    log_info "Checking dependencies..."
    
    local deps=(qt@5 wget)
    local to_install=()
    
    for dep in "${deps[@]}"; do
        if ! brew list "$dep" &>/dev/null; then
            to_install+=("$dep")
        fi
    done
    
    if [[ ${#to_install[@]} -gt 0 ]]; then
        log_info "Installing dependencies: ${to_install[*]}"
        brew install "${to_install[@]}"
    fi
    
    # Link Qt5 if needed
    if ! command -v qmake &>/dev/null; then
        log_info "Linking Qt5..."
        brew link qt@5 --force 2>/dev/null || true
    fi
    
    log_success "Dependencies installed"
}

function install_skyscraper() {
    if command -v Skyscraper &>/dev/null; then
        log_success "Skyscraper is already installed"
        return
    fi
    
    log_info "Installing Skyscraper..."
    
    local skysource="${HOME}/skysource"
    mkdir -p "$skysource"
    cd "$skysource"
    
    # Download and run the install script
    curl -sL https://raw.githubusercontent.com/muldjord/skyscraper/master/update_skyscraper.sh -o update_skyscraper.sh
    chmod +x update_skyscraper.sh
    
    # On macOS, we might need to use gtar
    if command -v gtar &>/dev/null; then
        sed -i '' 's/tar /gtar /g' update_skyscraper.sh
    fi
    
    ./update_skyscraper.sh
    
    cd - > /dev/null
    
    log_success "Skyscraper installed"
}

function setup_config_dir() {
    local config_dir="${HOME}/.config/skyscraper4miyoo"
    local skyscraper_dir="${HOME}/.skyscraper"
    
    log_info "Setting up configuration directories..."
    
    mkdir -p "$config_dir"
    mkdir -p "$skyscraper_dir"
    
    # Copy example config if it doesn't exist
    if [[ ! -f "$config_dir/config" ]]; then
        cp "$PROJECT_DIR/config/config.example" "$config_dir/config"
        log_info "Created config file: $config_dir/config"
    fi
    
    # Copy artwork files
    for artwork in "$PROJECT_DIR/artwork"/*.xml; do
        if [[ -f "$artwork" ]]; then
            cp "$artwork" "$skyscraper_dir/"
        fi
    done
    
    # Copy resources if they exist
    if [[ -d "$PROJECT_DIR/artwork/resources" ]]; then
        mkdir -p "$skyscraper_dir/resources"
        cp -r "$PROJECT_DIR/artwork/resources/"* "$skyscraper_dir/resources/" 2>/dev/null || true
    fi
    
    log_success "Configuration directories created"
}

function setup_skyscraper_config() {
    local skyscraper_ini="${HOME}/.skyscraper/config.ini"
    
    if [[ -f "$skyscraper_ini" ]]; then
        log_info "Skyscraper config already exists: $skyscraper_ini"
        read -p "Do you want to overwrite it? [y/N] " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            return
        fi
    fi
    
    log_info "Creating Skyscraper configuration..."
    
    # Get ROM path from user
    local default_rom_path="${HOME}/MiyooMini/Roms"
    read -r -p "Enter the path to your ROMs [$default_rom_path]: " rom_path
    rom_path="${rom_path:-$default_rom_path}"
    
    # Get ScreenScraper credentials
    echo ""
    echo "ScreenScraper credentials (optional but recommended for better scraping):"
    echo "Register at: https://www.screenscraper.fr/"
    echo ""
    log_warning "Note: Credentials will be stored in plain text in the config file."
    echo "       Consider using environment variables for sensitive data in production."
    echo ""
    read -r -p "ScreenScraper username (leave empty to skip): " ss_user
    if [[ -n "$ss_user" ]]; then
        read -r -s -p "ScreenScraper password: " ss_pass
        echo ""
    else
        ss_pass=""
    fi
    
    # Create config file
    cat > "$skyscraper_ini" << EOF
[main]
inputFolder="$rom_path"
artworkXml="artwork-miyoo1.xml"
cacheMarquees="false"
cacheTextures="false"
relativePaths="true"
gameListBackup="false"
nameTemplate="%t"
frontend="emulationstation"
EOF
    
    if [[ -n "$ss_user" ]]; then
        cat >> "$skyscraper_ini" << EOF

[screenscraper]
userCreds="$ss_user:$ss_pass"
EOF
    fi
    
    log_success "Skyscraper configuration created: $skyscraper_ini"
    
    # Create ROM directory if it doesn't exist
    if [[ ! -d "$rom_path" ]]; then
        mkdir -p "$rom_path"
        log_info "Created ROM directory: $rom_path"
    fi
}

function print_next_steps() {
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    log_success "Setup complete!"
    echo ""
    echo "Next steps:"
    echo ""
    echo "1. Copy your ROMs to the configured ROM directory"
    echo "   Organize them in folders by system (e.g., GBA/, SFC/, FC/)"
    echo ""
    echo "2. Run the scraper:"
    echo "   ./scripts/scrape.sh --all    # Scrape all systems"
    echo "   ./scripts/scrape.sh GBA SFC  # Scrape specific systems"
    echo ""
    echo "3. Copy the Imgs folders and miyoogamelist.xml files to your"
    echo "   Miyoo Mini SD card"
    echo ""
    echo "For more information, see: docs/USAGE.md"
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
}

# Main setup flow
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "         Skyscraper for Miyoo Mini - Setup"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

check_macos
check_homebrew
install_dependencies
install_skyscraper
setup_config_dir
setup_skyscraper_config
print_next_steps
