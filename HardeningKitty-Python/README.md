# HardeningKitty for Linux (Python Implementation)

## Overview

HardeningKitty for Linux is a security hardening tool for Rocky Linux and RHEL-based distributions, implemented in Python 3. This is a refactored version of the Windows HardeningKitty that provides the same security assessment and hardening capabilities for Linux systems.

## Features

- **Multiple Operating Modes**:
  - **Audit Mode**: Assess current system configuration against security benchmarks
  - **Config Mode**: Export current configuration for backup
  - **HailMary Mode**: Automatically apply hardening settings with backup
  - **Restore Mode**: Restore system from previous backup

- **Comprehensive Security Frameworks**:
  - CIS Rocky Linux 8 Benchmark (Level 1 & 2)
  - CIS Rocky Linux 9 Benchmark (Level 1 & 2)
  - DISA STIG for RHEL 8/9
  - Custom security baselines

- **Key Capabilities**:
  - Automated backup before changes
  - Detailed CSV and JSON reporting
  - Filtering by severity, category, or ID
  - Scoring system (1.0 - 6.0 scale)
  - Comprehensive logging
  - Modular architecture

## Requirements

- **Operating System**: Rocky Linux 8.x, 9.x (also compatible with RHEL, AlmaLinux, CentOS Stream)
- **Python**: Python 3.6 or higher (pre-installed on Rocky Linux)
- **Privileges**: Root/sudo access required
- **System Utilities**: systemctl, sysctl, auditctl, firewall-cmd, semanage, rpm, dnf

## Quick Start

```bash
# Basic audit
sudo python3 hardeningkitty.py --mode audit

# Audit with specific finding list
sudo python3 hardeningkitty.py --mode audit \
  --finding-list lists_linux/finding_list_cis_rocky_8_server_l1.csv \
  --emoji

# Apply hardening with backup
sudo python3 hardeningkitty.py --mode hailmary \
  --finding-list lists_linux/finding_list_cis_rocky_8_server_l1.csv \
  --backup

# Create configuration backup
sudo python3 hardeningkitty.py --mode config \
  --backup --backup-file /root/system_backup.json

# Restore from backup
sudo python3 hardeningkitty.py --mode restore \
  --backup-file /root/system_backup.json
```

## Installation

1. Clone or download this directory
2. No additional installation required (uses Python standard library)
3. Run as root/sudo

```bash
# Make executable
chmod +x hardeningkitty.py

# Run audit
sudo python3 hardeningkitty.py --mode audit --emoji
```

## Architecture

```
HardeningKitty-Python/
├── hardeningkitty.py          # Main entry point
├── lib/                       # Library modules
│   ├── __init__.py
│   ├── audit.py              # Audit mode
│   ├── hardening.py          # Hardening mode
│   ├── backup.py             # Backup/restore
│   ├── reporting.py          # Report generation
│   ├── methods.py            # Configuration methods
│   └── utils.py              # Utility functions
├── lists_linux/              # Finding lists
│   ├── finding_list_cis_rocky_8_server_l1.csv
│   └── finding_list_cis_rocky_8_server_l2.csv
├── examples/                 # Usage examples
├── requirements.txt          # Python dependencies
├── LINUX_ARCHITECTURE.md     # Architecture documentation
└── README_LINUX.md           # Detailed documentation
```

## Usage Examples

### Filtering

```bash
# Filter by severity
sudo python3 hardeningkitty.py --mode audit --filter-severity High

# Filter by category
sudo python3 hardeningkitty.py --mode audit --filter-category "Network Configuration"

# Filter by ID
sudo python3 hardeningkitty.py --mode audit --filter-id 3.2.1
```

### Reporting

```bash
# Generate CSV report and log
sudo python3 hardeningkitty.py --mode audit \
  --report audit_report.csv \
  --log audit.log \
  --verbose
```

### Incremental Hardening

```bash
# Apply by category
sudo python3 hardeningkitty.py --mode hailmary \
  --finding-list lists_linux/finding_list_cis_rocky_8_server_l1.csv \
  --filter-category "Network Configuration" \
  --backup
```

## Configuration Methods

The Python implementation supports 18+ Linux configuration methods:

- **sysctl**: Kernel parameters
- **config_file**: Configuration files (SSH, login.defs, etc.)
- **service**: systemd services
- **package**: RPM package management
- **permission**: File/directory permissions
- **ownership**: File/directory ownership
- **mount**: Filesystem mount options
- **selinux**: SELinux configuration
- **auditd**: Audit rules
- **firewalld**: Firewall rules
- **grub**: Boot configuration
- **modprobe**: Kernel modules
- **pam**: PAM authentication
- **file_exists**: File existence checks
- **command**: Custom shell commands

All methods use native Linux tools (sysctl, systemctl, etc.) via subprocess calls.

## Advantages

- ✅ Zero additional dependencies (uses Python standard library)
- ✅ Modular architecture (easy to extend)
- ✅ Fast startup and execution
- ✅ Lightweight footprint
- ✅ Works out of the box on all Linux distributions
- ✅ Clear separation of concerns

## Documentation

- **README_LINUX.md**: Comprehensive user guide
- **LINUX_ARCHITECTURE.md**: Technical architecture details
- **examples/**: Shell scripts demonstrating usage

## Example Scripts

- `examples/basic_audit.sh`: Simple audit with reporting
- `examples/apply_hardening.sh`: Full hardening with backup
- `examples/audit_high_severity.sh`: High-severity checks only

## Scoring System

- **Passed**: 4 points (😻)
- **Low Severity**: 2 points (😿)
- **Medium Severity**: 1 point (🙀)
- **High Severity**: 0 points (😾)

**Score**: `(Achieved Points / Maximum Points) × 5 + 1` (Scale: 1.0 - 6.0)

## Compatibility

| OS | Version | Status |
|----|---------|--------|
| Rocky Linux | 8.x | ✅ Fully Supported |
| Rocky Linux | 9.x | ✅ Fully Supported |
| RHEL | 8.x | ✅ Compatible |
| RHEL | 9.x | ✅ Compatible |
| AlmaLinux | 8.x | ✅ Compatible |
| AlmaLinux | 9.x | ✅ Compatible |
| CentOS Stream | 8, 9 | ✅ Compatible |

## License

MIT License - See LICENSE file for details

## Credits

- Original HardeningKitty for Windows by Michael Schneider (scip ag)
- Refactored for Linux using Python 3
- Based on CIS Benchmarks, DISA STIG, and security best practices

## Support

For issues, questions, or contributions, please refer to the main HardeningKitty repository.
