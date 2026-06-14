#!/bin/bash

# OpenCore Kext Builder Script
# Uses Lilu-and-Friends to build Acidanthera kexts from source

set -e

KEXTS_DIR="$(dirname "$0")/EFI/OC/Kexts"
LILU_DIR="${LILU_AND_FRIENDS_DIR:-$HOME/Lilu-and-Friends}"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log_info() { echo -e "${GREEN}[INFO]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

# Kexts built by Lilu-and-Friends (matching plugins.json names)
LILU_KEXTS=(
    Lilu
    WhateverGreen
    AppleALC
    VirtualSMC
    IntelMausi
    NVMeFix
    IntelBluetoothFirmware
    itlwm
)

echo "========================================"
echo "     OpenCore Kext Builder Script"
echo "     Powered by Lilu-and-Friends"
echo "========================================"
echo ""

# Check prerequisites
if [ ! -d "$KEXTS_DIR" ]; then
    log_error "Kexts directory not found: $KEXTS_DIR"
    exit 1
fi

# Clone Lilu-and-Friends if missing
if [ ! -d "$LILU_DIR" ]; then
    log_info "Cloning Lilu-and-Friends to $LILU_DIR..."
    git clone https://github.com/corpnewt/Lilu-and-Friends "$LILU_DIR"
else
    log_info "Lilu-and-Friends found at $LILU_DIR"
fi

# Build kexts
log_info "Building kexts (this may take a while)..."

# Build args array: -k Lilu -k WhateverGreen ...
build_args=(-m build)
for k in "${LILU_KEXTS[@]}"; do
    build_args+=(-k "$k")
done

"$LILU_DIR/Run.command" "${build_args[@]}"

# Copy built kexts into EFI
log_info "Copying kexts to $KEXTS_DIR..."
temp_dir=$(mktemp -d)
trap 'rm -rf "$temp_dir"' EXIT

for kext_name in "${LILU_KEXTS[@]}"; do
    # Find the latest zip for this kext
    zip_file=$(ls -t "$LILU_DIR/Kexts/${kext_name}"-*.zip 2>/dev/null | head -1)
    if [ -z "$zip_file" ]; then
        log_warn "No build output for $kext_name — skipping"
        continue
    fi

    unzip -qo "$zip_file" -d "$temp_dir/$kext_name"

    # Copy all .kext bundles from the extracted output
    find "$temp_dir/$kext_name" -name "*.kext" -maxdepth 3 -type d | while read -r kext_path; do
        kext_basename=$(basename "$kext_path")
        rm -rf "$KEXTS_DIR/$kext_basename"
        cp -R "$kext_path" "$KEXTS_DIR/"
        log_info "Updated $kext_basename"
    done
done

# USBToolBox (not built by Lilu-and-Friends — download pre-built release)
log_info "Fetching USBToolBox from GitHub..."
usb_release=$(curl -s "https://api.github.com/repos/USBToolBox/kext/releases/latest")
usb_url=$(echo "$usb_release" | grep -o '"browser_download_url": *"[^"]*\.zip"' | head -1 | grep -o 'http[^"]*')
if [ -n "$usb_url" ]; then
    curl -sLo "$temp_dir/USBToolBox.zip" "$usb_url"
    unzip -qo "$temp_dir/USBToolBox.zip" -d "$temp_dir/USBToolBox"
    usb_kext=$(find "$temp_dir/USBToolBox" -name "USBToolBox.kext" -type d | head -1)
    if [ -n "$usb_kext" ]; then
        rm -rf "$KEXTS_DIR/USBToolBox.kext"
        cp -R "$usb_kext" "$KEXTS_DIR/"
        log_info "Updated USBToolBox.kext"
    fi
fi

echo ""
echo "========================================"
log_info "Kext update complete!"
echo "========================================"
echo ""
log_warn "Note: UTBMap.kext is machine-specific and was not updated."
log_warn "Please verify your config.plist is compatible with the new kext versions."
