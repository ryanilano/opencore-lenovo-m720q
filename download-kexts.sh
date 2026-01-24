#!/bin/bash

# OpenCore Kext Updater Script
# Automatically downloads the latest kexts from their respective GitHub releases

set -e

KEXTS_DIR="$(dirname "$0")/EFI/OC/Kexts"
TEMP_DIR=$(mktemp -d)

cleanup() {
    rm -rf "$TEMP_DIR"
}
trap cleanup EXIT

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

log_info() { echo -e "${GREEN}[INFO]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

# Download and extract a kext from GitHub releases
download_kext() {
    local repo=$1
    local kext_name=$2
    local asset_pattern=$3
    
    log_info "Fetching latest release for $kext_name from $repo..."
    
    # Get latest release info
    local release_info=$(curl -s "https://api.github.com/repos/$repo/releases/latest")
    local tag=$(echo "$release_info" | grep '"tag_name"' | head -1 | sed -E 's/.*"tag_name": *"([^"]+)".*/\1/')
    
    if [ -z "$tag" ]; then
        log_error "Failed to get latest release for $repo"
        return 1
    fi
    
    log_info "Latest version: $tag"
    
    # Find the download URL matching the pattern
    local download_url=$(echo "$release_info" | grep '"browser_download_url"' | grep -E "$asset_pattern" | head -1 | sed -E 's/.*"browser_download_url": *"([^"]+)".*/\1/')
    
    if [ -z "$download_url" ]; then
        log_error "Failed to find download URL for $kext_name (pattern: $asset_pattern)"
        return 1
    fi
    
    log_info "Downloading from: $download_url"
    
    local filename=$(basename "$download_url")
    local download_path="$TEMP_DIR/$filename"
    
    curl -L -o "$download_path" "$download_url"
    
    # Extract based on file type
    local extract_dir="$TEMP_DIR/extract_$kext_name"
    mkdir -p "$extract_dir"
    
    if [[ "$filename" == *.zip ]]; then
        unzip -q "$download_path" -d "$extract_dir"
    elif [[ "$filename" == *.tar.gz ]] || [[ "$filename" == *.tgz ]]; then
        tar -xzf "$download_path" -C "$extract_dir"
    fi
    
    # Find and copy the kext(s)
    if [ -n "$4" ]; then
        # Multiple kexts specified
        for kext in "${@:4}"; do
            local kext_path=$(find "$extract_dir" -name "$kext" -type d | head -1)
            if [ -n "$kext_path" ]; then
                rm -rf "$KEXTS_DIR/$kext"
                cp -R "$kext_path" "$KEXTS_DIR/"
                log_info "Updated $kext"
            else
                log_warn "Could not find $kext in archive"
            fi
        done
    else
        local kext_path=$(find "$extract_dir" -name "$kext_name" -type d | head -1)
        if [ -n "$kext_path" ]; then
            rm -rf "$KEXTS_DIR/$kext_name"
            cp -R "$kext_path" "$KEXTS_DIR/"
            log_info "Updated $kext_name"
        else
            log_warn "Could not find $kext_name in archive"
        fi
    fi
}

echo "========================================"
echo "     OpenCore Kext Updater Script"
echo "========================================"
echo ""
echo "Kexts directory: $KEXTS_DIR"
echo ""

# Check if kexts directory exists
if [ ! -d "$KEXTS_DIR" ]; then
    log_error "Kexts directory not found: $KEXTS_DIR"
    exit 1
fi

# Lilu (dependency for many other kexts, update first)
download_kext "acidanthera/Lilu" "Lilu.kext" "RELEASE\.zip"

# VirtualSMC
download_kext "acidanthera/VirtualSMC" "VirtualSMC.kext" "VirtualSMC-.*-RELEASE\.zip"

# AppleALC
download_kext "acidanthera/AppleALC" "AppleALC.kext" "RELEASE\.zip"

# WhateverGreen
download_kext "acidanthera/WhateverGreen" "WhateverGreen.kext" "RELEASE\.zip"

# IntelMausi
download_kext "acidanthera/IntelMausi" "IntelMausi.kext" "RELEASE\.zip"

# NVMeFix
download_kext "acidanthera/NVMeFix" "NVMeFix.kext" "RELEASE\.zip"

# IntelBluetoothFirmware (contains multiple kexts)
log_info "Fetching latest release for IntelBluetoothFirmware..."
release_info=$(curl -s "https://api.github.com/repos/OpenIntelWireless/IntelBluetoothFirmware/releases/latest")
tag=$(echo "$release_info" | grep '"tag_name"' | head -1 | sed -E 's/.*"tag_name": *"([^"]+)".*/\1/')
log_info "Latest version: $tag"
download_url=$(echo "$release_info" | grep '"browser_download_url"' | grep -E '\.zip' | head -1 | sed -E 's/.*"browser_download_url": *"([^"]+)".*/\1/')
if [ -n "$download_url" ]; then
    curl -L -o "$TEMP_DIR/IntelBluetooth.zip" "$download_url"
    extract_dir="$TEMP_DIR/extract_IntelBluetooth"
    mkdir -p "$extract_dir"
    unzip -q "$TEMP_DIR/IntelBluetooth.zip" -d "$extract_dir"
    
    for kext in IntelBluetoothFirmware.kext IntelBTPatcher.kext BlueToolFixup.kext; do
        kext_path=$(find "$extract_dir" -name "$kext" -type d | head -1)
        if [ -n "$kext_path" ]; then
            rm -rf "$KEXTS_DIR/$kext"
            cp -R "$kext_path" "$KEXTS_DIR/"
            log_info "Updated $kext"
        fi
    done
fi

# itlwm (Intel WiFi)
download_kext "OpenIntelWireless/itlwm" "itlwm.kext" "itlwm_.*_stable\.kext\.zip"

# USBToolBox
download_kext "USBToolBox/kext" "USBToolBox.kext" "RELEASE\.zip"

echo ""
echo "========================================"
log_info "Kext update complete!"
echo "========================================"
echo ""
log_warn "Note: UTBMap.kext is machine-specific and was not updated."
log_warn "Please verify your config.plist is compatible with the new kext versions."
