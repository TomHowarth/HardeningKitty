# HardeningKitty for Linux - Implementations

This repository contains **two complete implementations** of HardeningKitty for Linux (Rocky Linux and RHEL-based distributions), each optimized for different use cases and audiences.

## Overview

HardeningKitty has been refactored from Windows to Linux in two implementations:

1. **[HardeningKitty-Python](./HardeningKitty-Python/)** - Python 3 implementation
2. **[HardeningKitty-PowerShell](./HardeningKitty-PowerShell/)** - PowerShell Core implementation

Both implementations provide the same security hardening capabilities based on CIS Benchmarks, DISA STIG, and security best practices, but with different approaches and advantages.

## Quick Comparison

| Feature | Python | PowerShell Core |
|---------|--------|-----------------|
| **Installation** | Built-in on Linux | Requires PowerShell Core |
| **Dependencies** | None (standard library) | PowerShell 7.0+ (~60MB) |
| **Syntax** | Python 3.6+ | PowerShell (same as Windows) |
| **Best For** | Linux admins, automation | Windows admins, analysis |
| **Startup Speed** | Fast | Moderate |
| **Filtering** | Predefined options | Advanced ScriptBlocks |
| **Pipeline** | Limited | Full PowerShell pipeline |
| **Data Export** | CSV, JSON | CSV, JSON, XML, HTML |
| **Object Handling** | Dictionaries | Native PowerShell objects |
| **Code Structure** | Modular (7 files) | Single module |

## Which Implementation Should You Use?

### Use Python Implementation If:

✅ You want **zero additional dependencies**
✅ Your team is **comfortable with Python**
✅ You need a **lightweight solution**
✅ You're running on systems where **installing PowerShell is difficult**
✅ You prefer **modular code structure**
✅ You want **faster startup times**
✅ You're primarily doing **automated audits**

**Get Started:**
```bash
cd HardeningKitty-Python
sudo python3 hardeningkitty.py --mode audit --emoji
```

### Use PowerShell Core Implementation If:

✅ Your team **already uses Windows HardeningKitty**
✅ You want **consistency across Windows/Linux**
✅ You need **advanced PowerShell features** (pipeline, objects)
✅ You want **powerful filtering and data manipulation**
✅ Your team is **familiar with PowerShell**
✅ You need **easy integration with other PowerShell scripts**
✅ You're doing **interactive analysis and reporting**

**Get Started:**
```bash
# Install PowerShell Core first
sudo dnf install -y https://github.com/PowerShell/PowerShell/releases/download/v7.4.0/powershell-7.4.0-1.rh.x86_64.rpm

cd HardeningKitty-PowerShell
sudo pwsh
Import-Module ./HardeningKitty-Linux.psm1
Invoke-HardeningKitty -Mode Audit -EmojiSupport
```

## Hybrid Approach

You can use **both implementations** on the same system:

```bash
# Daily automated audit (Python - lightweight, fast)
0 2 * * * /usr/bin/python3 /opt/HardeningKitty-Python/hardeningkitty.py --mode audit --report /var/log/audit.csv

# Manual investigation (PowerShell - powerful, flexible)
pwsh -Command "Import-Module /opt/HardeningKitty-PowerShell/HardeningKitty-Linux.psm1; Invoke-HardeningKitty -Filter { \$_.Severity -eq 'High' }"
```

## Feature Parity

Both implementations provide:

- ✅ Audit, Config, and HailMary modes
- ✅ Same CSV finding lists (100% compatible)
- ✅ CIS Rocky Linux 8 & 9 Benchmarks (Level 1 & 2)
- ✅ 18+ Linux configuration methods
- ✅ Native tool integration (sysctl, systemctl, auditd, etc.)
- ✅ Automatic backup before changes
- ✅ Scoring system (1.0 - 6.0)
- ✅ CSV reporting and logging
- ✅ Filtering capabilities
- ✅ Emoji support 😻

## Implementation Details

### Python Implementation

**Location:** `HardeningKitty-Python/`

**Architecture:**
```
hardeningkitty.py          # Main entry point
lib/
├── audit.py               # Audit mode logic
├── hardening.py           # Hardening mode logic
├── backup.py              # Backup/restore
├── reporting.py           # Report generation
├── methods.py             # Configuration methods
└── utils.py               # Helper functions
```

**Example:**
```bash
cd HardeningKitty-Python

# Basic audit
sudo python3 hardeningkitty.py --mode audit

# Filter high severity
sudo python3 hardeningkitty.py --mode audit --filter-severity High

# Apply hardening
sudo python3 hardeningkitty.py --mode hailmary \
  --finding-list lists_linux/finding_list_cis_rocky_8_server_l1.csv \
  --backup --report report.csv
```

**Advantages:**
- No installation required
- Modular architecture
- Fast execution
- Lightweight
- Familiar to Linux administrators

**Documentation:** [HardeningKitty-Python/README.md](./HardeningKitty-Python/README.md)

### PowerShell Core Implementation

**Location:** `HardeningKitty-PowerShell/`

**Architecture:**
```
HardeningKitty-Linux.psm1  # Main module (single file)
HardeningKitty-Linux.psd1  # Module manifest
```

**Example:**
```powershell
cd HardeningKitty-PowerShell
sudo pwsh

# Import module
Import-Module ./HardeningKitty-Linux.psm1

# Basic audit
Invoke-HardeningKitty -Mode Audit -EmojiSupport

# Advanced filtering
Invoke-HardeningKitty -Filter { $_.Severity -eq "High" -and $_.Category -like "*Network*" }

# Pipeline and export
Invoke-HardeningKitty -Mode Audit |
  Where-Object { $_.TestResult -ne "Passed" } |
  Export-Csv failed_checks.csv
```

**Advantages:**
- Same structure as Windows HardeningKitty
- Full PowerShell pipeline
- Advanced filtering (ScriptBlocks)
- Object-based output
- Multiple export formats
- Powerful data manipulation

**Documentation:** [HardeningKitty-PowerShell/README.md](./HardeningKitty-PowerShell/README.md)

## Finding Lists

Both implementations use the **same finding lists** (CSV format):

- `lists_linux/finding_list_cis_rocky_8_server_l1.csv` - 115+ Level 1 checks
- `lists_linux/finding_list_cis_rocky_8_server_l2.csv` - 180+ Level 2 checks

Finding lists are 100% compatible between implementations.

## Native Tool Usage

**Both implementations use native Linux tools:**

- `sysctl` - Kernel parameters
- `systemctl` - Service management
- `auditctl` - Audit rules
- `firewall-cmd` - Firewall configuration
- `rpm`, `dnf` - Package management
- `stat`, `chmod` - File permissions
- `getenforce`, `setenforce` - SELinux
- `grub2-mkconfig` - Boot configuration
- `mount` - Filesystem options

The difference is in **how they call these tools**:
- **Python**: `subprocess.run()`
- **PowerShell**: `Invoke-Expression`

## Migration Between Implementations

Finding lists and reports are compatible, making it easy to switch:

### From Python to PowerShell

```powershell
# Install PowerShell
sudo dnf install powershell

# Use existing finding lists
sudo pwsh
Import-Module ./HardeningKitty-PowerShell/HardeningKitty-Linux.psm1
Invoke-HardeningKitty -FileFindingList ../HardeningKitty-Python/lists_linux/finding_list_cis_rocky_8_server_l1.csv
```

### From PowerShell to Python

```bash
# Use existing finding lists
sudo python3 HardeningKitty-Python/hardeningkitty.py \
  --finding-list HardeningKitty-PowerShell/lists_linux/finding_list_cis_rocky_8_server_l1.csv \
  --mode audit
```

## Performance Comparison

**Audit of 100 findings:**

| Implementation | Startup Time | Execution Time | Total Time |
|----------------|--------------|----------------|------------|
| Python | ~0.5s | ~5-8s | ~5.5-8.5s |
| PowerShell | ~2-3s | ~6-9s | ~8-12s |

Python is faster for automated/scheduled tasks, PowerShell provides better interactive experience.

## Use Cases

### Automated Daily Audits → Python

```bash
#!/bin/bash
# /etc/cron.daily/hardeningkitty-audit

/usr/bin/python3 /opt/HardeningKitty-Python/hardeningkitty.py \
  --mode audit \
  --report /var/log/hardening/audit_$(date +%Y%m%d).csv \
  --log /var/log/hardening/audit.log \
  --quiet
```

**Why Python:** Fast, lightweight, no GUI overhead

### Interactive Analysis → PowerShell

```powershell
# Find top 10 failing checks
Import-Module ./HardeningKitty-PowerShell/HardeningKitty-Linux.psm1

$Results = Invoke-HardeningKitty -Mode Audit

$Results |
  Where-Object { $_.TestResult -ne "Passed" } |
  Group-Object Severity |
  Sort-Object Count -Descending |
  Select-Object -First 10 |
  Format-Table -AutoSize

# Export to multiple formats
$Results | Export-Csv report.csv
$Results | ConvertTo-Json | Out-File report.json
$Results | ConvertTo-Html | Out-File report.html
```

**Why PowerShell:** Rich data manipulation, multiple export formats, pipeline

### Incremental Hardening → Either

**Python:**
```bash
for category in "Initial Setup" "Services" "Network Configuration"; do
    sudo python3 hardeningkitty.py --mode hailmary \
      --filter-category "$category" --backup
done
```

**PowerShell:**
```powershell
$Categories = @("Initial Setup", "Services", "Network Configuration")
foreach ($Category in $Categories) {
    Invoke-HardeningKitty -Mode HailMary `
      -Filter { $_.Category -eq $Category } `
      -Backup
}
```

## Installation Options

### Option 1: Install Both (Recommended for flexibility)

```bash
# Clone repository
git clone https://github.com/yourusername/HardeningKitty.git
cd HardeningKitty

# Python is ready to use
cd HardeningKitty-Python
sudo python3 hardeningkitty.py --mode audit

# Install PowerShell for additional capabilities
sudo dnf install -y powershell
cd ../HardeningKitty-PowerShell
sudo pwsh -Command "Import-Module ./HardeningKitty-Linux.psm1; Invoke-HardeningKitty -Mode Audit"
```

### Option 2: Python Only (Lightweight)

```bash
# Clone and use Python only
git clone https://github.com/yourusername/HardeningKitty.git
cd HardeningKitty/HardeningKitty-Python
sudo python3 hardeningkitty.py --mode audit
```

### Option 3: PowerShell Only (Windows admin teams)

```bash
# Install PowerShell Core first
sudo dnf install -y powershell

# Clone and use PowerShell only
git clone https://github.com/yourusername/HardeningKitty.git
cd HardeningKitty/HardeningKitty-PowerShell
sudo pwsh
Import-Module ./HardeningKitty-Linux.psm1
Invoke-HardeningKitty -Mode Audit
```

## Compatibility

Both implementations support:

- Rocky Linux 8.x, 9.x
- RHEL 8.x, 9.x
- AlmaLinux 8.x, 9.x
- CentOS Stream 8, 9

## Contributing

Contributions are welcome to both implementations! Each implementation is self-contained and can be enhanced independently.

## License

MIT License - See LICENSE file in each implementation directory

## Credits

- Original HardeningKitty for Windows by Michael Schneider (scip ag)
- Python implementation for Linux
- PowerShell Core implementation for Linux
- Based on CIS Benchmarks, DISA STIG, and security best practices

## Support

Choose the implementation that best fits your team's skills and infrastructure. Both provide production-ready security hardening for Rocky Linux and RHEL-based distributions.

For detailed documentation, see:
- **Python**: [HardeningKitty-Python/README.md](./HardeningKitty-Python/README.md)
- **PowerShell**: [HardeningKitty-PowerShell/README.md](./HardeningKitty-PowerShell/README.md)
- **Comparison**: [IMPLEMENTATION_COMPARISON.md](./IMPLEMENTATION_COMPARISON.md)
