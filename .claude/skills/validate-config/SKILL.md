---
name: validate-config
description: Validate OpenCore config.plist syntax with plutil. Use after editing config.plist or when troubleshooting boot issues.
---

Run plist syntax validation on the main OpenCore configuration:

```bash
plutil -lint EFI/OC/config.plist
```

If the validation fails, read the error output and fix the config.plist at the reported location.
If validation passes, report "config.plist is valid."
