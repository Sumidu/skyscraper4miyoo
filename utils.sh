#!/bin/bash
# =============================================================================
# Shared utility functions for Skyscraper scripts
# =============================================================================

# Get the folder name for a platform
# Uses custom PLATFORM_FOLDER_<platform> if set, otherwise tries lowercase then uppercase
get_platform_folder() {
    local platform="$1"
    local folder_var="PLATFORM_FOLDER_${platform}"
    local custom_folder="${!folder_var}"
    
    # If custom folder is set, use it
    if [[ -n "$custom_folder" ]]; then
        echo "$custom_folder"
        return
    fi
    
    # Otherwise, try platform name (lowercase first, then uppercase)
    if [[ -d "${ROM_BASE_PATH}/${platform}" ]]; then
        echo "$platform"
    else
        echo "$platform" | tr '[:lower:]' '[:upper:]'
    fi
}
