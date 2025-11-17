# HardeningKitty for Linux (PowerShell Core Implementation)

## Overview

HardeningKitty for Linux is a security hardening tool for Rocky Linux and RHEL-based distributions, implemented in PowerShell Core. This maintains the same architecture and familiar PowerShell syntax as the Windows HardeningKitty while targeting Linux systems.

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

- **PowerShell Features**:
  - Full PowerShell pipeline support
  - Advanced filtering with ScriptBlocks
  - Native PowerShell objects
  - Multiple export formats (CSV, JSON, XML, HTML)
  - Object manipulation and analysis
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

## Quick Start

```powershell
# Launch PowerShell as root
sudo pwsh

# Import module
Import-Module ./HardeningKitty-Linux.psm1

# Basic audit with emoji
Invoke-HardeningKitty -Mode Audit -EmojiSupport

# Advanced filtering
Invoke-HardeningKitty -Filter { $_.Severity -eq "High" } -EmojiSupport

# Apply hardening with backup
Invoke-HardeningKitty -Mode HailMary -Backup -Log -Report

# Export to multiple formats
Invoke-HardeningKitty -Mode Audit | Export-Csv report.csv
Invoke-HardeningKitty -Mode Audit | ConvertTo-Json | Out-File report.json
```

## Architecture

```
HardeningKitty-PowerShell/
├── HardeningKitty-Linux.psm1      # Main PowerShell module (~1,200 lines)
├── HardeningKitty-Linux.psd1      # Module manifest
├── lists_linux/                   # Finding lists
│   ├── finding_list_cis_rocky_8_server_l1.csv
│   └── finding_list_cis_rocky_8_server_l2.csv
├── examples_powershell/           # Usage examples
│   ├── basic_audit.ps1
│   ├── apply_hardening.ps1
│   ├── audit_high_severity.ps1
│   └── incremental_hardening.ps1
└── README_POWERSHELL_LINUX.md     # Detailed documentation
```

## PowerShell-Specific Features

### Object-Based Output

Results are PowerShell objects that can be manipulated:

```powershell
# Capture results
$Results = Invoke-HardeningKitty -Mode Audit

# Filter high severity issues
$HighIssues = $Results | Where-Object { $_.TestResult -eq "High" }

# Export to different formats
$Results | Export-Csv -Path report.csv
$Results | ConvertTo-Json | Out-File report.json
$Results | Export-Clixml -Path report.xml
$Results | ConvertTo-Html | Out-File report.html

# Group by category
$Results | Group-Object -Property Category | Format-Table Count, Name

# Get statistics
$Results | Group-Object TestResult | Select-Object Name, Count
```

### Pipeline Support

```powershell
# Complex filtering and analysis
Invoke-HardeningKitty -Mode Audit |
  Where-Object { $_.TestResult -ne "Passed" } |
  Group-Object Severity |
  Sort-Object Count -Descending |
  Format-Table -AutoSize

# Export filtered results
Invoke-HardeningKitty -Mode Audit |
  Where-Object { $_.Severity -eq "High" -or $_.Severity -eq "Medium" } |
  Export-Csv high_medium_issues.csv
```

### Advanced Filtering

```powershell
# ScriptBlock filtering
Invoke-HardeningKitty -Filter { $_.Severity -eq "High" }

Invoke-HardeningKitty -Filter { $_.Category -like "*Network*" }

Invoke-HardeningKitty -Filter { $_.ID -match "^3\." }

Invoke-HardeningKitty -Filter {
    ($_.Severity -eq "High" -or $_.Severity -eq "Medium") -and
    $_.Category -notlike "*User*"
}

# Regex matching
Invoke-HardeningKitty -Filter { $_.Name -match "ssh|firewall" }
```

## Usage Examples

### Basic Audit

```powershell
Import-Module ./HardeningKitty-Linux.psm1

# Simple audit
Invoke-HardeningKitty -Mode Audit

# With emoji and logging
Invoke-HardeningKitty -Mode Audit -EmojiSupport -Log -Report
```

### Apply Hardening

```powershell
# Full hardening with backup
Invoke-HardeningKitty -Mode HailMary `
  -FileFindingList lists_linux/finding_list_cis_rocky_8_server_l1.csv `
  -Backup `
  -Log `
  -Report

# Category-specific hardening
Invoke-HardeningKitty -Mode HailMary `
  -Filter { $_.Category -eq "Network Configuration" } `
  -Backup
```

### Configuration Backup

```powershell
# Export current configuration
Invoke-HardeningKitty -Mode Config `
  -Backup `
  -BackupFile "/root/backup_$(Get-Date -Format 'yyyyMMdd').csv"
```

### Analysis and Reporting

```powershell
# Get detailed statistics
$Results = Invoke-HardeningKitty -Mode Audit

Write-Host "Total Checks: $($Results.Count)"
Write-Host "Passed: $(($Results | Where-Object { $_.TestResult -eq 'Passed' }).Count)"
Write-Host "Failed: $(($Results | Where-Object { $_.TestResult -ne 'Passed' }).Count)"

# Find top failing categories
$Results |
  Where-Object { $_.TestResult -ne "Passed" } |
  Group-Object Category |
  Sort-Object Count -Descending |
  Select-Object -First 5 Name, Count |
  Format-Table -AutoSize
```

## Configuration Methods

The PowerShell implementation supports 18+ Linux configuration methods:

- **Get/Set-SysctlValue**: Kernel parameters
- **Get/Set-ConfigFileValue**: Configuration files
- **Get/Set-ServiceStatus**: systemd services
- **Get-PackageStatus, Install/Remove-Package**: RPM packages
- **Get/Set-FilePermission**: File permissions
- **Get-MountOption**: Filesystem mount options
- **Get/Set-SELinuxMode**: SELinux configuration
- **Get/Add-AuditRule**: auditd rules
- **Get/Set-GrubParameter**: Boot configuration
- **Get/Set-ModprobeBlacklist**: Kernel modules

All methods use native Linux tools via `Invoke-Expression`.

## Advantages of PowerShell Implementation

- ✅ **Consistency**: Same structure as Windows HardeningKitty
- ✅ **Object-Oriented**: Native PowerShell objects (not text parsing)
- ✅ **Pipeline Support**: Full PowerShell pipeline integration
- ✅ **Advanced Filtering**: PowerShell ScriptBlock syntax
- ✅ **Built-in Cmdlets**: Export-Csv, ConvertTo-Json, etc.
- ✅ **Familiar Syntax**: Teams using Windows version can easily adopt
- ✅ **Cross-Platform**: PowerShell Core works on Windows, Linux, macOS
- ✅ **Rich Ecosystem**: Access to PowerShell modules and gallery

## Example Scripts

The `examples_powershell/` directory contains ready-to-use scripts:

- **basic_audit.ps1**: Simple audit with emoji and reporting
- **apply_hardening.ps1**: Full hardening with user confirmation
- **audit_high_severity.ps1**: Check only high-severity findings
- **incremental_hardening.ps1**: Category-by-category hardening with prompts

Run examples:

```bash
sudo pwsh
./examples_powershell/basic_audit.ps1
```

## Automation

### Daily Audit Script

```powershell
#!/usr/bin/pwsh
# /etc/cron.daily/hardeningkitty-audit.ps1

Import-Module /opt/HardeningKitty-PowerShell/HardeningKitty-Linux.psm1

$Date = Get-Date -Format "yyyyMMdd"
$Results = Invoke-HardeningKitty -Mode Audit -SkipSystemInformation

# Save report
$Results | Export-Csv "/var/log/hardening/audit_$Date.csv" -NoTypeInformation

# Alert on high severity issues
$HighIssues = $Results | Where-Object { $_.TestResult -eq "High" }
if ($HighIssues.Count -gt 0) {
    Write-Host "WARNING: Found $($HighIssues.Count) high severity issues!"
    # Add email notification here
}
```

### Scheduled Task

```bash
# Add to crontab
0 2 * * * /usr/bin/pwsh /opt/HardeningKitty-PowerShell/daily_audit.ps1
```

## Scoring System

- **Passed**: 4 points (😻)
- **Low Severity**: 2 points (😿)
- **Medium Severity**: 1 point (🙀)
- **High Severity**: 0 points (😾)

**Score**: `(Achieved Points / Maximum Points) × 5 + 1` (Scale: 1.0 - 6.0)

**Interpretation**:
- 5.5 - 6.0: Excellent
- 5.0 - 5.5: Very Good
- 4.5 - 5.0: Good
- 4.0 - 4.5: Fair
- 3.0 - 4.0: Poor
- 1.0 - 3.0: Bogus

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

## Documentation

- **README_POWERSHELL_LINUX.md**: Comprehensive user guide with advanced examples
- **HardeningKitty-Linux.psd1**: Module manifest with metadata

## License

MIT License - See LICENSE file for details

## Credits

- Original HardeningKitty for Windows by Michael Schneider (scip ag)
- PowerShell Core implementation for Linux
- PowerShell Core by Microsoft
- Based on CIS Benchmarks, DISA STIG, and security best practices

## Support

For issues, questions, or contributions, please refer to the main HardeningKitty repository.

## Why PowerShell on Linux?

PowerShell Core brings powerful features to Linux administration:

1. **Consistent Experience**: Same syntax across Windows and Linux
2. **Object Pipeline**: Work with structured data, not just text
3. **Advanced Scripting**: Full programming language capabilities
4. **Rich Ecosystem**: Access to PowerShell Gallery modules
5. **Cross-Platform**: Write once, run on Windows, Linux, macOS

The PowerShell implementation uses native Linux tools (sysctl, systemctl, etc.) while providing PowerShell's superior data handling and scripting capabilities.
