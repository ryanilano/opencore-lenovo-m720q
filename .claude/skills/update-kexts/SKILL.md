---
name: update-kexts
description: Download the latest kexts for this OpenCore EFI using download-kexts.sh. Use when kexts need updating or after initial clone.
disable-model-invocation: true
---

Run the kext downloader script with safety checks:

1. First, validate the current config.plist: `plutil -lint EFI/OC/config.plist`
2. If valid, run the downloader: `./download-kexts.sh`
3. After downloading, re-validate config.plist: `plutil -lint EFI/OC/config.plist`
4. Report which kexts were updated (the script outputs this) and whether validation passed.

If the config.plist is invalid before starting, fix it first before downloading kexts.
