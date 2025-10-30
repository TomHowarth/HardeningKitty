# HardeningKitty-Linux

## Overview

HardeningKitty-Linux is a security hardening tool for Rocky Linux (and RHEL-based distributions) refactored from the Windows-based HardeningKitty. It implements CIS Benchmarks, DISA STIG, and security best practices to assess and harden Linux systems.

## Features

- **Multiple Operating Modes**:
  - **Audit Mode**: Assess current system configuration against security benchmarks
  - **Config Mode**: Export current configuration for backup
  - **HailMary Mode**: Automatically apply hardening settings
  - **Restore Mode**: Restore system from previous backup

- **Comprehensive Security Frameworks**:
  - CIS Rocky Linux 8 Benchmark (Level 1 & 2)
  - CIS Rocky Linux 9 Benchmark (Level 1 & 2)
  - DISA STIG for RHEL 8/9
  - Custom security baselines

- **Advanced Features**:
  - Automated backup before changes
  - Detailed CSV and JSON reporting
  - Filtering by severity, category, or ID
  - Scoring system (1.0 - 6.0 scale)
  - Comprehensive logging

## Requirements

- **Operating System**: Rocky Linux 8.x, 9.x (also compatible with RHEL, AlmaLinux, CentOS Stream)
- **Python**: Python 3.6 or higher
- **Privileges**: Root/sudo access required for most operations
- **System Utilities**: systemctl, sysctl, auditctl, firewall-cmd, semanage

## Installation

1. Clone the repository:
```bash
git clone https://github.com/yourusername/HardeningKitty.git
cd HardeningKitty
```

2. Make the script executable:
```bash
chmod +x hardeningkitty.py
```

3. Install dependencies (if needed):
```bash
pip3 install -r requirements.txt
```

## Quick Start

### Basic Audit
```bash
sudo python3 hardeningkitty.py --mode audit
```

### Audit with Specific Finding List
```bash
sudo python3 hardeningkitty.py --mode audit \
  --finding-list lists_linux/finding_list_cis_rocky_8_server_l1.csv
```

### Apply Hardening (with automatic backup)
```bash
sudo python3 hardeningkitty.py --mode hailmary \
  --finding-list lists_linux/finding_list_cis_rocky_8_server_l1.csv \
  --backup
```

### Create Configuration Backup
```bash
sudo python3 hardeningkitty.py --mode config \
  --backup --backup-file /root/system_backup.json
```

### Restore from Backup
```bash
sudo python3 hardeningkitty.py --mode restore \
  --backup-file /root/system_backup.json
```

## Usage Examples

### Audit with Filtering

Filter by severity:
```bash
sudo python3 hardeningkitty.py --mode audit --filter-severity High
```

Filter by category:
```bash
sudo python3 hardeningkitty.py --mode audit --filter-category "Network Configuration"
```

Filter by ID:
```bash
sudo python3 hardeningkitty.py --mode audit --filter-id 3.2.1
```

### Generate Reports

CSV report:
```bash
sudo python3 hardeningkitty.py --mode audit \
  --report audit_report.csv \
  --log audit.log
```

With emoji support:
```bash
sudo python3 hardeningkitty.py --mode audit --emoji
```

Verbose output:
```bash
sudo python3 hardeningkitty.py --mode audit --verbose
```

### Hardening with Custom Options

Skip backup (not recommended):
```bash
sudo python3 hardeningkitty.py --mode hailmary \
  --finding-list lists_linux/finding_list_cis_rocky_8_server_l1.csv \
  --skip-backup --yes
```

Apply only specific findings:
```bash
sudo python3 hardeningkitty.py --mode hailmary \
  --finding-list lists_linux/finding_list_cis_rocky_8_server_l1.csv \
  --filter-category "Network Configuration" \
  --backup
```

## Command-Line Options

```
--mode {audit,config,hailmary,restore}
    Operational mode (default: audit)

--finding-list PATH
    Path to finding list CSV file

--filter-id ID
    Filter by finding ID

--filter-category CATEGORY
    Filter by category

--filter-severity {High,Medium,Low}
    Filter by severity level

--filter-method METHOD
    Filter by method

--report PATH
    Generate CSV report file

--log PATH
    Generate log file

--emoji
    Enable emoji support in output

--verbose
    Enable verbose output

--quiet
    Minimal output

--backup
    Create backup before changes

--backup-file PATH
    Backup file path

--skip-backup
    Skip backup creation (not recommended)

--yes
    Automatically answer yes to prompts

--version
    Show version information
```

## Finding Lists

### Available Finding Lists

- **CIS Rocky Linux 8 Server Level 1**: `lists_linux/finding_list_cis_rocky_8_server_l1.csv`
  - Essential security settings with minimal impact on functionality
  - 115+ checks covering:
    - Initial setup (filesystem, bootloader, SELinux)
    - Service configuration
    - Network parameters
    - Logging and auditing
    - Access control and authentication
    - System maintenance

- **CIS Rocky Linux 8 Server Level 2**: `lists_linux/finding_list_cis_rocky_8_server_l2.csv`
  - Level 1 + additional stringent security measures
  - 180+ checks including:
    - All Level 1 checks
    - Additional service restrictions
    - Enhanced network security
    - Advanced auditing
    - Stricter file permissions
    - User account hardening

### Finding List Format

Finding lists are CSV files with the following columns:

```csv
ID,Category,Name,Method,MethodArgument,ConfigPath,ConfigKey,ClassName,Namespace,Property,DefaultValue,RecommendedValue,Operator,Severity
```

Example:
```csv
3.2.1,Network Configuration,Ensure packet redirect sending is disabled,sysctl,net.ipv4.conf.all.send_redirects,,,,,,,0,=,High
5.2.8,Access Authentication Authorization,Ensure SSH root login is disabled,config_file,,/etc/ssh/sshd_config,PermitRootLogin,,,,,no,=,High
```

## Configuration Methods

HardeningKitty-Linux supports various methods to check and apply settings:

| Method | Description | Example |
|--------|-------------|---------|
| sysctl | Kernel parameters | `net.ipv4.ip_forward` |
| config_file | Configuration files | `/etc/ssh/sshd_config` |
| service | systemd services | `firewalld` |
| package | Package installation | `aide` |
| permission | File permissions | `/etc/passwd` |
| ownership | File ownership | `/etc/shadow` |
| mount | Filesystem mount options | `/tmp` |
| selinux | SELinux configuration | Enforcing mode |
| auditd | Audit rules | time-change |
| firewalld | Firewall rules | ssh service |
| grub | GRUB configuration | audit=1 |
| modprobe | Kernel modules | cramfs |
| pam | PAM configuration | pam_faillock.so |
| command | Custom commands | Shell commands |

## Scoring System

HardeningKitty-Linux uses a scoring system from 1.0 to 6.0:

- **Passed**: 4 points (😻)
- **Low Severity**: 2 points (😿)
- **Medium Severity**: 1 point (🙀)
- **High Severity**: 0 points (😾)

**Score Calculation**: `(Achieved Points / Maximum Points) × 5 + 1`

**Score Interpretation**:
- 5.5 - 6.0: Excellent
- 5.0 - 5.5: Very Good
- 4.5 - 5.0: Good
- 4.0 - 4.5: Fair
- 3.0 - 4.0: Poor
- 1.0 - 3.0: Bogus

## Architecture

```
HardeningKitty-Linux/
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
├── LINUX_ARCHITECTURE.md     # Architecture documentation
├── README_LINUX.md           # This file
└── requirements.txt          # Python dependencies
```

## Security Considerations

1. **Backup Before Hardening**: Always create a backup before applying hardening settings
2. **Test in Non-Production**: Test hardening configurations in a non-production environment first
3. **Review Finding Lists**: Review and customize finding lists for your environment
4. **Understand Changes**: Understand what each setting does before applying
5. **Reboot May Be Required**: Some changes require a system reboot to take effect
6. **SELinux**: Ensure SELinux is properly configured before and after hardening
7. **Service Availability**: Some hardening may affect service availability

## Troubleshooting

### Permission Denied
```bash
# Solution: Run with sudo
sudo python3 hardeningkitty.py --mode audit
```

### Module Not Found
```bash
# Solution: Ensure you're in the correct directory
cd /path/to/HardeningKitty
python3 -c "import sys; print(sys.path)"
```

### SELinux Prevents Changes
```bash
# Check SELinux status
sudo getenforce

# If needed, temporarily set to permissive
sudo setenforce 0

# Re-run hardening
sudo python3 hardeningkitty.py --mode hailmary ...

# Set back to enforcing
sudo setenforce 1
```

### Restore from Backup Fails
```bash
# Manually restore specific files if needed
sudo cp /etc/sshd_config.bak.TIMESTAMP /etc/ssh/sshd_config
sudo systemctl restart sshd
```

## Best Practices

1. **Incremental Hardening**: Start with Level 1, then move to Level 2
2. **Category-by-Category**: Apply hardening by category to isolate issues
3. **Monitor After Changes**: Monitor system logs after applying changes
4. **Document Changes**: Keep records of what was changed and when
5. **Regular Audits**: Run audits regularly to maintain security posture
6. **Keep Backups**: Maintain multiple backups at different stages
7. **Update Finding Lists**: Keep finding lists updated with latest benchmarks

## Compatibility

| OS | Version | Status |
|----|---------|--------|
| Rocky Linux | 8.x | ✅ Fully Supported |
| Rocky Linux | 9.x | ✅ Fully Supported |
| RHEL | 8.x | ✅ Compatible |
| RHEL | 9.x | ✅ Compatible |
| AlmaLinux | 8.x | ✅ Compatible |
| AlmaLinux | 9.x | ✅ Compatible |
| CentOS Stream | 8 | ✅ Compatible |
| CentOS Stream | 9 | ✅ Compatible |

## Contributing

Contributions are welcome! Please:

1. Fork the repository
2. Create a feature branch
3. Add tests for new functionality
4. Submit a pull request

## License

MIT License - See LICENSE file for details

## Credits

- Original HardeningKitty for Windows by Michael Schneider (scip ag)
- Refactored for Linux by the HardeningKitty-Linux team
- Based on CIS Benchmarks, DISA STIG, and security best practices

## References

- [CIS Benchmarks](https://www.cisecurity.org/cis-benchmarks/)
- [DISA STIG](https://public.cyber.mil/stigs/)
- [Red Hat Security Guide](https://access.redhat.com/documentation/en-us/red_hat_enterprise_linux/8/html/security_hardening/index)
- [Rocky Linux Documentation](https://docs.rockylinux.org/)

## Support

For issues, questions, or contributions:
- GitHub Issues: https://github.com/yourusername/HardeningKitty/issues
- Documentation: See LINUX_ARCHITECTURE.md

## Changelog

### Version 1.0.0 (Initial Release)
- Refactored from Windows HardeningKitty
- Support for Rocky Linux 8 and 9
- CIS Benchmark Level 1 and Level 2 finding lists
- Audit, Config, HailMary, and Restore modes
- Backup and restore functionality
- CSV and JSON reporting
- Comprehensive logging
