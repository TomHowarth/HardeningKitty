# HardeningKitty-Linux Architecture

## Overview
Refactored version of HardeningKitty for Rocky Linux (RHEL derivative) hardening based on CIS Benchmarks and security best practices.

## Technology Stack
- **Language**: Python 3.6+ (native to Rocky Linux)
- **Privilege Management**: sudo integration
- **Configuration Format**: CSV finding lists (maintains compatibility with original structure)
- **Output Formats**: Console, CSV reports, JSON logs

## Operational Modes

### 1. Audit Mode (Default)
- Reads current system configuration
- Compares against CIS Benchmark recommendations
- Generates scoring and severity ratings
- Output: Console + optional CSV/JSON report

### 2. Config Mode
- Exports current system configuration
- Creates backup for restoration
- No assessment or comparison

### 3. HailMary Mode
- Applies hardening settings automatically
- Creates system snapshot before changes
- Modifies configurations according to finding lists
- Requires root/sudo privileges

### 4. Restore Mode
- Restores system from previous backup
- Reverts hardening changes

## Linux Configuration Methods (Mapped from Windows)

| Windows Method | Linux Equivalent | Implementation |
|----------------|------------------|----------------|
| Registry | Config Files | /etc/sysctl.conf, /etc/default/, /etc/sysconfig/ |
| secedit | PAM + login.defs | /etc/pam.d/, /etc/login.defs, /etc/security/ |
| auditpol | auditd | /etc/audit/rules.d/, auditctl |
| accesschk | User/Group permissions | /etc/sudoers, /etc/group, /etc/passwd |
| accountpolicy | PAM password policy | /etc/security/pwquality.conf, /etc/login.defs |
| WindowsOptionalFeature | systemd services | systemctl enable/disable |
| service | systemd services | systemctl start/stop/status |
| MpComputerStatus | SELinux status | getenforce, sestatus |
| MpPreference | Firewall rules | firewalld, iptables |
| BitLockerVolume | LUKS encryption | cryptsetup status |
| FirewallRule | Firewall rules | firewall-cmd, iptables |
| bcdedit | GRUB configuration | /etc/default/grub, grubby |
| CimInstance | System information | /proc, /sys, sysctl |
| ScheduledTask | cron/systemd timers | crontab, /etc/cron.d/, systemctl list-timers |
| Processmitigation | Kernel hardening | sysctl kernel parameters, ASLR, PIE |
| localaccount | User account settings | /etc/passwd, /etc/shadow, chage |
| LanguageMode | Shell restrictions | /etc/shells, AppArmor, SELinux |

## Linux-Specific Methods

| Method | Purpose | Implementation |
|--------|---------|----------------|
| sysctl | Kernel parameters | /etc/sysctl.conf, /etc/sysctl.d/ |
| modprobe | Kernel module blacklist | /etc/modprobe.d/ |
| pam | Authentication policies | /etc/pam.d/ |
| selinux | Mandatory access control | /etc/selinux/config, semanage |
| firewalld | Firewall configuration | firewall-cmd |
| aide | File integrity | /etc/aide.conf |
| auditd | Audit framework | /etc/audit/auditd.conf, audit rules |
| grub | Boot configuration | /etc/default/grub, /boot/grub2/ |
| permissions | File/directory permissions | chmod, chown, ACLs |
| packages | Package management | dnf/yum (installed/removed) |
| mounts | Filesystem mount options | /etc/fstab |
| network | Network configuration | /etc/sysconfig/network-scripts/, nmcli |

## Finding List Structure (CSV)

Maintains original 14-column structure with Linux adaptations:

```csv
ID,Category,Name,Method,MethodArgument,ConfigPath,ConfigKey,ClassName,Namespace,Property,DefaultValue,RecommendedValue,Operator,Severity
1001,Kernel Parameters,Disable IP forwarding,sysctl,net.ipv4.ip_forward,/etc/sysctl.conf,net.ipv4.ip_forward,,,,,0,=,High
1002,Filesystem,Ensure /tmp is mounted with nodev,mount,/tmp,/etc/fstab,/tmp,,,,,nodev,contains,Medium
1003,Services,Ensure telnet server is disabled,service,telnet,,,,,,,disabled,=,High
```

## Security Frameworks for Rocky Linux

### Implemented Baselines
1. **CIS Rocky Linux 8 Benchmark** (Levels 1 & 2, Server & Workstation)
2. **CIS Rocky Linux 9 Benchmark** (Levels 1 & 2, Server & Workstation)
3. **DISA STIG for RHEL 8/9** (DoD compliance)
4. **OpenSCAP Security Profiles** (PCI-DSS, HIPAA)

## Scoring System (Same as Windows)

- **Passed**: 4 points
- **Low Severity**: 2 points
- **Medium Severity**: 1 point
- **High Severity**: 0 points

**Formula**: `Score = (Achieved / Maximum) × 5 + 1` (Scale: 1.0 - 6.0)

## Privilege Requirements

### Root/Sudo Required For:
- System configuration modifications (/etc/)
- Service management (systemctl)
- Kernel parameter changes (sysctl -w)
- Firewall rules (firewall-cmd)
- Audit rules (auditctl)
- SELinux configuration (semanage)
- Package installation/removal (dnf/yum)
- User/group management
- File permission changes outside home directory

### User Privileges Sufficient For:
- Audit mode (read-only checks)
- Config mode (reading current state)
- Report generation

## File Structure

```
HardeningKitty-Linux/
├── hardeningkitty.py              # Main Python module
├── lib/
│   ├── __init__.py
│   ├── methods.py                 # Configuration method implementations
│   ├── audit.py                   # Audit mode logic
│   ├── hardening.py               # HailMary mode logic
│   ├── backup.py                  # Backup/restore functionality
│   ├── reporting.py               # Report generation
│   └── utils.py                   # Helper functions
├── lists/                         # Finding lists (CSV)
│   ├── finding_list_cis_rocky_8_server_l1.csv
│   ├── finding_list_cis_rocky_8_server_l2.csv
│   ├── finding_list_cis_rocky_9_server_l1.csv
│   ├── finding_list_cis_rocky_9_server_l2.csv
│   └── finding_list_disa_stig_rhel8.csv
├── tests/                         # Unit tests
├── examples/                      # Usage examples
├── README.md                      # Documentation
└── requirements.txt               # Python dependencies
```

## Dependencies

```
- Python 3.6+
- Root/sudo access
- System utilities: systemctl, sysctl, auditctl, firewall-cmd, semanage
- Python packages: pyyaml, python-pam, argparse, csv, json
```

## Usage Examples

```bash
# Basic audit
sudo python3 hardeningkitty.py --mode audit

# Audit with specific finding list
sudo python3 hardeningkitty.py --mode audit --finding-list lists/finding_list_cis_rocky_8_server_l1.csv

# Apply hardening (HailMary mode)
sudo python3 hardeningkitty.py --mode hailmary --finding-list lists/finding_list_cis_rocky_8_server_l1.csv --backup

# Create configuration backup
sudo python3 hardeningkitty.py --mode config --backup --backup-file /root/system_backup.json

# Restore from backup
sudo python3 hardeningkitty.py --mode restore --backup-file /root/system_backup.json

# Filter by severity
sudo python3 hardeningkitty.py --mode audit --severity High

# Generate report
sudo python3 hardeningkitty.py --mode audit --report report.csv --log audit.log
```

## Key Design Principles

1. **Non-Destructive Default**: Audit mode is read-only
2. **Mandatory Backup**: HailMary mode creates snapshot before changes
3. **Idempotent Operations**: Re-running hardening is safe
4. **Comprehensive Logging**: All changes tracked and reversible
5. **Privilege Separation**: Minimal required privileges per operation
6. **Framework Flexibility**: Support multiple compliance frameworks
7. **Graceful Degradation**: Skip unavailable checks with warnings

## Error Handling

- Missing dependencies → Skip check, log warning
- Insufficient privileges → Skip check, continue with accessible checks
- Application failure → Log error, offer rollback from backup
- Service unavailable → Skip check, mark as "Not Applicable"

## Compatibility

- **Rocky Linux**: 8.x, 9.x (primary target)
- **RHEL**: 8.x, 9.x (fully compatible)
- **AlmaLinux**: 8.x, 9.x (compatible)
- **CentOS Stream**: 8, 9 (compatible with minor adjustments)
