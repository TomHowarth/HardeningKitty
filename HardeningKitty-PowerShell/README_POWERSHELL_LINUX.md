# HardeningKitty for Linux (PowerShell Core)

## Overview

HardeningKitty for Linux is a security hardening tool for Rocky Linux and RHEL-based distributions, implemented in PowerShell Core. This is a refactored version of the Windows HardeningKitty that maintains the same architecture and familiar PowerShell syntax while targeting Linux systems.

## Why PowerShell Core?

- **Consistency**: Maintains similar code structure to the original Windows version
- **Cross-Platform**: PowerShell Core 7+ runs natively on Linux
- **Object-Oriented**: Superior data handling compared to text parsing
- **Familiar Syntax**: Teams already familiar with Windows HardeningKitty can easily adopt this
- **Native Tool Integration**: Calls native Linux tools (sysctl, systemctl, etc.) while providing PowerShell's benefits

## Features

- **Multiple Operating Modes**:
  - **Audit Mode**: Assess current system configuration against security benchmarks
  - **Config Mode**: Export current configuration for backup
  - **HailMary Mode**: Automatically apply hardening settings with backup

- **Comprehensive Security Frameworks**:
  - CIS Rocky Linux 8 Benchmark (Level 1 & 2)
  - CIS Rocky Linux 9 Benchmark (Level 1 & 2)
  - DISA STIG for RHEL 8/9
  - Custom security baselines

- **Advanced Features**:
  - Automated backup before changes
  - Detailed CSV reporting
  - Filtering by severity, category, or ID
  - Scoring system (1.0 - 6.0 scale)
  - Comprehensive logging
  - Emoji support 😻

## Requirements

### System Requirements
- **Operating System**: Rocky Linux 8.x, 9.x (also compatible with RHEL, AlmaLinux, CentOS Stream)
- **PowerShell**: PowerShell Core 7.0 or higher
- **Privileges**: Root/sudo access required
- **System Utilities**: systemctl, sysctl, auditctl, firewall-cmd, semanage, rpm, dnf

### Installing PowerShell Core on Rocky Linux

```bash
# Rocky Linux 8/9
sudo dnf install -y https://github.com/PowerShell/PowerShell/releases/download/v7.4.0/powershell-7.4.0-1.rh.x86_64.rpm

# Verify installation
pwsh --version
```

## Installation

1. Clone the repository:
```bash
git clone https://github.com/yourusername/HardeningKitty.git
cd HardeningKitty
```

2. Launch PowerShell:
```bash
sudo pwsh
```

3. Import the module:
```powershell
Import-Module ./HardeningKitty-Linux.psm1
```

## Quick Start

### Basic Audit
```powershell
# Launch PowerShell as root
sudo pwsh

# Import module
Import-Module ./HardeningKitty-Linux.psm1

# Run basic audit
Invoke-HardeningKitty -Mode Audit -EmojiSupport
```

### Audit with Specific Finding List
```powershell
Invoke-HardeningKitty -Mode Audit `
  -FileFindingList lists_linux/finding_list_cis_rocky_8_server_l1.csv `
  -Report `
  -Log
```

### Apply Hardening (with automatic backup)
```powershell
Invoke-HardeningKitty -Mode HailMary `
  -FileFindingList lists_linux/finding_list_cis_rocky_8_server_l1.csv `
  -Backup `
  -Log `
  -Report
```

### Create Configuration Backup
```powershell
Invoke-HardeningKitty -Mode Config `
  -Backup `
  -BackupFile "/root/system_backup_$(Get-Date -Format 'yyyyMMdd').csv"
```

## Usage Examples

### Audit with Filtering

Filter by severity:
```powershell
Invoke-HardeningKitty -Mode Audit `
  -Filter { $_.Severity -eq "High" } `
  -EmojiSupport
```

Filter by category:
```powershell
Invoke-HardeningKitty -Mode Audit `
  -Filter { $_.Category -eq "Network Configuration" }
```

Filter by ID:
```powershell
Invoke-HardeningKitty -Mode Audit `
  -Filter { $_.ID -eq "3.2.1" }
```

Multiple filters:
```powershell
Invoke-HardeningKitty -Mode Audit `
  -Filter { $_.Severity -eq "High" -and $_.Category -like "*Network*" }
```

### Generate Reports

CSV report with logging:
```powershell
Invoke-HardeningKitty -Mode Audit `
  -Report `
  -ReportFile "/var/log/hardening/audit_report.csv" `
  -Log `
  -LogFile "/var/log/hardening/audit.log"
```

With emoji support:
```powershell
Invoke-HardeningKitty -Mode Audit `
  -EmojiSupport `
  -Report `
  -Log
```

Skip system information:
```powershell
Invoke-HardeningKitty -Mode Audit `
  -SkipSystemInformation
```

### Hardening with Custom Options

Apply only specific category:
```powershell
Invoke-HardeningKitty -Mode HailMary `
  -FileFindingList lists_linux/finding_list_cis_rocky_8_server_l1.csv `
  -Filter { $_.Category -eq "Network Configuration" } `
  -Backup `
  -Log
```

Skip backup (NOT RECOMMENDED):
```powershell
Invoke-HardeningKitty -Mode HailMary `
  -FileFindingList lists_linux/finding_list_cis_rocky_8_server_l1.csv `
  -SkipBackup
```

## Command Parameters

### -Mode
Operational mode (default: Audit)
- **Audit**: Assess system configuration
- **Config**: Export current configuration
- **HailMary**: Apply hardening settings

### -FileFindingList
Path to finding list CSV file (default: lists_linux/finding_list_cis_rocky_8_server_l1.csv)

### -EmojiSupport
Enable emoji in output for better visual feedback

### -Log
Create a log file (automatically named)

### -LogFile
Specify custom log file path

### -Report
Generate CSV report (automatically named)

### -ReportFile
Specify custom report file path

### -Backup
Create backup of current configuration

### -BackupFile
Specify custom backup file path

### -SkipSystemInformation
Don't display system information

### -SkipBackup
Skip backup creation in HailMary mode (NOT RECOMMENDED)

### -Filter
PowerShell ScriptBlock to filter findings
```powershell
-Filter { $_.Severity -eq "High" }
-Filter { $_.ID -like "3.*" }
-Filter { $_.Category -match "Network" }
```

## Finding Lists

### Available Finding Lists

1. **CIS Rocky Linux 8 Server Level 1** (`lists_linux/finding_list_cis_rocky_8_server_l1.csv`)
   - 115+ essential security checks
   - Minimal impact on functionality
   - Recommended for all systems

2. **CIS Rocky Linux 8 Server Level 2** (`lists_linux/finding_list_cis_rocky_8_server_l2.csv`)
   - 180+ comprehensive security checks
   - Includes all Level 1 checks plus additional restrictions
   - For high-security environments

### Finding List Format

Same CSV format as Windows version:
```csv
ID,Category,Name,Method,MethodArgument,ConfigPath,ConfigKey,ClassName,Namespace,Property,DefaultValue,RecommendedValue,Operator,Severity
```

## Configuration Methods

HardeningKitty for Linux supports various methods to check and apply settings:

| Method | Description | Linux Tool | Example |
|--------|-------------|------------|---------|
| sysctl | Kernel parameters | `sysctl` | net.ipv4.ip_forward |
| config_file | Configuration files | Direct file I/O | /etc/ssh/sshd_config |
| service | systemd services | `systemctl` | firewalld |
| package | Package management | `rpm`, `dnf` | aide |
| permission | File permissions | `stat`, `chmod` | /etc/passwd |
| mount | Filesystem mount options | `mount` | /tmp |
| selinux | SELinux configuration | `getenforce`, `setenforce` | enforcing |
| auditd | Audit rules | `auditctl` | time-change |
| grub | GRUB configuration | `grub2-mkconfig` | audit=1 |
| modprobe | Kernel modules | `lsmod`, `modprobe` | cramfs |
| file_exists | File existence check | `Test-Path` | /etc/motd |
| command | Custom shell commands | `Invoke-Expression` | Custom validation |

## Scoring System

HardeningKitty uses a 1.0 to 6.0 scoring system:

| Result | Points | Emoji |
|--------|--------|-------|
| Passed | 4 | 😻 |
| Low Severity | 2 | 😿 |
| Medium Severity | 1 | 🙀 |
| High Severity | 0 | 😾 |

**Score Calculation**: `(Achieved Points / Maximum Points) × 5 + 1`

**Score Interpretation**:
- **5.5 - 6.0**: Excellent - System is well hardened
- **5.0 - 5.5**: Very Good - Minor improvements needed
- **4.5 - 5.0**: Good - Some hardening applied
- **4.0 - 4.5**: Fair - Significant gaps exist
- **3.0 - 4.0**: Poor - Major security concerns
- **1.0 - 3.0**: Bogus - System is not hardened

## PowerShell-Specific Features

### Object-Based Output
Results are PowerShell objects that can be manipulated:

```powershell
# Capture results
$Results = Invoke-HardeningKitty -Mode Audit | Select-Object -Skip 10

# Filter high severity issues
$HighIssues = $Results | Where-Object { $_.TestResult -eq "High" }

# Export to different formats
$Results | Export-Csv -Path report.csv
$Results | ConvertTo-Json | Out-File report.json
$Results | Export-Clixml -Path report.xml

# Group by category
$Results | Group-Object -Property Category | Format-Table Count, Name
```

### Pipeline Support
```powershell
# Get all network-related findings
Get-Content lists_linux/finding_list_cis_rocky_8_server_l1.csv |
  ConvertFrom-Csv |
  Where-Object { $_.Category -like "*Network*" } |
  Export-Csv -Path network_findings.csv
```

### Advanced Filtering
```powershell
# Complex filters using PowerShell
Invoke-HardeningKitty -Mode Audit -Filter {
    ($_.Severity -eq "High" -or $_.Severity -eq "Medium") -and
    $_.Category -notlike "*User*"
}

# Regex matching
Invoke-HardeningKitty -Mode Audit -Filter {
    $_.ID -match "^[123]\."
}
```

## Architecture

```
HardeningKitty/
├── HardeningKitty-Linux.psm1      # Main PowerShell module
├── HardeningKitty-Linux.psd1      # Module manifest
├── lists_linux/                   # Finding lists
│   ├── finding_list_cis_rocky_8_server_l1.csv
│   └── finding_list_cis_rocky_8_server_l2.csv
├── examples_powershell/           # Usage examples
└── README_POWERSHELL_LINUX.md     # This file
```

## Comparison: Python vs PowerShell

| Aspect | Python Version | PowerShell Version |
|--------|----------------|-------------------|
| Installation | Built-in Python | Requires PowerShell Core |
| Syntax | Python | PowerShell (more familiar to Windows admins) |
| Object Handling | Dictionary/List | Native PowerShell objects |
| Piping | Limited | Full PowerShell pipeline support |
| Output Formatting | Print statements | PowerShell formatting cmdlets |
| Data Export | CSV, JSON libraries | Built-in Export-Csv, ConvertTo-Json |
| Filtering | Python expressions | PowerShell ScriptBlocks |
| Code Structure | Python classes | PowerShell functions |
| Compatibility | Original: Windows | Same structure as Windows version |

## Best Practices

1. **Always Run as Root**
   ```powershell
   # Check if running as root
   if ((Invoke-Expression "whoami") -ne "root") {
       Write-Error "Must run as root"
       exit
   }
   ```

2. **Create Backups Before Hardening**
   ```powershell
   Invoke-HardeningKitty -Mode HailMary -Backup
   ```

3. **Test in Non-Production First**
   - Use audit mode first to understand impact
   - Apply category by category
   - Monitor system after changes

4. **Use Filtering for Incremental Hardening**
   ```powershell
   # Start with high severity
   Invoke-HardeningKitty -Mode HailMary `
     -Filter { $_.Severity -eq "High" } `
     -Backup

   # Then medium
   Invoke-HardeningKitty -Mode HailMary `
     -Filter { $_.Severity -eq "Medium" } `
     -Backup
   ```

5. **Regular Audits**
   ```powershell
   # Schedule regular audits
   # Add to cron or systemd timer
   0 2 * * 0 /usr/bin/pwsh -Command "Import-Module /path/to/HardeningKitty-Linux.psm1; Invoke-HardeningKitty -Mode Audit -Report -Log"
   ```

## Troubleshooting

### PowerShell Not Found
```bash
# Install PowerShell Core
sudo dnf install -y https://github.com/PowerShell/PowerShell/releases/download/v7.4.0/powershell-7.4.0-1.rh.x86_64.rpm
```

### Permission Denied
```powershell
# Must run as root
sudo pwsh
```

### Module Not Loading
```powershell
# Use full path
Import-Module /full/path/to/HardeningKitty-Linux.psm1 -Force
```

### SELinux Blocks Changes
```bash
# Temporarily set to permissive if needed
sudo setenforce 0

# Apply hardening
sudo pwsh -Command "Import-Module ./HardeningKitty-Linux.psm1; Invoke-HardeningKitty -Mode HailMary -Backup"

# Set back to enforcing
sudo setenforce 1
```

## Examples Scripts

### Daily Audit Script
```powershell
#!/usr/bin/pwsh
# daily_audit.ps1

Import-Module ./HardeningKitty-Linux.psm1

$Date = Get-Date -Format "yyyyMMdd"
$ReportPath = "/var/log/hardening/audit_$Date.csv"
$LogPath = "/var/log/hardening/audit_$Date.log"

Invoke-HardeningKitty `
    -Mode Audit `
    -Report `
    -ReportFile $ReportPath `
    -Log `
    -LogFile $LogPath `
    -SkipSystemInformation

# Send email if high severity issues found
$Report = Import-Csv $ReportPath
$HighIssues = $Report | Where-Object { $_.TestResult -eq "High" }

if ($HighIssues.Count -gt 0) {
    Write-Host "WARNING: Found $($HighIssues.Count) high severity issues!"
    # Add email notification here
}
```

### Incremental Hardening Script
```powershell
#!/usr/bin/pwsh
# incremental_hardening.ps1

Import-Module ./HardeningKitty-Linux.psm1

$Categories = @(
    "Initial Setup",
    "Services",
    "Network Configuration",
    "Logging and Auditing",
    "Access Authentication Authorization",
    "System Maintenance"
)

foreach ($Category in $Categories) {
    Write-Host "`n=== Hardening: $Category ===`n"

    Invoke-HardeningKitty `
        -Mode HailMary `
        -Filter { $_.Category -eq $Category } `
        -Backup `
        -BackupFile "/root/backup_$(Get-Date -Format 'yyyyMMdd_HHmmss')_$($Category -replace ' ','_').csv" `
        -Log

    Write-Host "`nCompleted: $Category. Press Enter to continue..."
    Read-Host
}
```

## Contributing

Contributions are welcome! The PowerShell version maintains compatibility with the Windows version's architecture, making cross-platform improvements easier.

## License

MIT License - See LICENSE file for details

## Credits

- Original HardeningKitty for Windows by Michael Schneider (scip ag)
- PowerShell Core by Microsoft
- CIS Benchmarks by Center for Internet Security
- DISA STIG by Defense Information Systems Agency

## Support

For issues, questions, or contributions:
- GitHub Issues: https://github.com/yourusername/HardeningKitty/issues
- Documentation: See LINUX_ARCHITECTURE.md

## Changelog

### Version 1.0.0 (Initial Release)
- PowerShell Core 7+ implementation for Linux
- Support for Rocky Linux 8 and 9
- CIS Benchmark Level 1 and Level 2 finding lists
- Audit, Config, and HailMary modes
- Backup and restore functionality
- CSV reporting
- Native Linux tool integration
- PowerShell pipeline support
- Advanced filtering capabilities
