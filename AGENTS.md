# AGENTS.md

This file provides guidance to AI coding tools when working in this repository.

## Project context
OpenCore EFI configuration for a Lenovo M720q Tiny (i3-8100T / UHD 630 / ALC235 / Intel AX210), targeting macOS Sequoia with SMBIOS `Macmini8,1`.

This is a configuration repo — no build system, test suite, or package manager. The core file is `EFI/OC/config.plist`. Kexts are gitignored (except `UTBMap.kext`) and fetched via `./download-kexts.sh`. SMBIOS serial/UUID/MLB fields in config.plist are intentionally blank.
