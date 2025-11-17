# HardeningKitty for Debian/Ubuntu (Python Implementation)

## Overview

HardeningKitty for Debian/Ubuntu is a security hardening tool for Debian-based Linux distributions, implemented in Python 3. This is adapted specifically for Debian/Ubuntu systems with support for their native tools (APT, UFW, AppArmor).

## Key Features for Debian/Ubuntu

- **APT Package Management**: Uses `apt`/`dpkg` instead of `dnf`/`rpm`
- **UFW Firewall**: Uncomplicated Firewall support instead of firewalld
- **AppArmor**: Mandatory Access Control (replaces SELinux)
- **systemd-timesyncd**: Ubuntu's default time synchronization
- **CIS Benchmarks**: Ubuntu 22.04, 20.04, Debian 11 support

## Quick Start

```bash
# Basic audit
sudo python3 hardeningkitty.py --mode audit --emoji

# Apply Ubuntu hardening
sudo python3 hardeningkitty.py --mode hailmary \
  --finding-list lists_linux/finding_list_cis_ubuntu_22_04_server_l1.csv \
  --backup
```

## Requirements

- Ubuntu 20.04+, Debian 11+, Linux Mint 21+
- Python 3.6+ (pre-installed)
- Root/sudo access
- Tools: apt, ufw, apparmor, auditd

## Installation

```bash
chmod +x hardeningkitty.py
sudo python3 hardeningkitty.py --mode audit
```

## Debian vs RHEL Differences

| Feature | RHEL Version | Debian Version |
|---------|--------------|----------------|
| Package Manager | dnf/rpm | apt/dpkg |
| Firewall | firewalld | UFW |
| MAC | SELinux | AppArmor |
| Time Sync | chronyd | systemd-timesyncd |

## Compatibility

✅ Ubuntu Server 22.04 LTS, 20.04 LTS  
✅ Debian 11 (Bullseye), 12 (Bookworm)  
✅ Linux Mint 21+, Pop!_OS 22.04+

## License

MIT License

## Related Projects

- Original: HardeningKitty (Windows)
- RHEL/Rocky: HardeningKitty-Python (Rocky Linux)
- PowerShell: HardeningKitty-PowerShell (Linux)
