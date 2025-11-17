@{
    # Script module or binary module file associated with this manifest.
    RootModule = 'HardeningKitty-Linux.psm1'

    # Version number of this module.
    ModuleVersion = '1.0.0'

    # ID used to uniquely identify this module
    GUID = '7f3d8ab2-2cd3-4ee9-a1b7-5c4e6f8a9d0e'

    # Author of this module
    Author = 'HardeningKitty for Linux - Refactored from Windows version by Michael Schneider'

    # Company or vendor of this module
    CompanyName = 'Community'

    # Copyright statement for this module
    Copyright = '(c) 2024 HardeningKitty Contributors. Licensed under MIT.'

    # Description of the functionality provided by this module
    Description = 'HardeningKitty for Linux - Security hardening tool for Rocky Linux and RHEL-based distributions. Implements CIS Benchmarks, DISA STIG, and security best practices to assess and harden Linux systems.'

    # Minimum version of the PowerShell engine required by this module
    PowerShellVersion = '7.0'

    # Functions to export from this module
    FunctionsToExport = @('Invoke-HardeningKitty')

    # Cmdlets to export from this module
    CmdletsToExport = @()

    # Variables to export from this module
    VariablesToExport = @()

    # Aliases to export from this module
    AliasesToExport = @()

    # Private data to pass to the module specified in RootModule/ModuleToProcess
    PrivateData = @{
        PSData = @{
            # Tags applied to this module for module discovery
            Tags = @('Security', 'Hardening', 'CIS', 'Benchmark', 'Linux', 'Rocky', 'RHEL', 'Audit', 'Compliance')

            # A URL to the license for this module
            LicenseUri = 'https://github.com/yourusername/HardeningKitty/blob/main/LICENSE'

            # A URL to the main website for this project
            ProjectUri = 'https://github.com/yourusername/HardeningKitty'

            # ReleaseNotes of this module
            ReleaseNotes = @'
# HardeningKitty for Linux v1.0.0

## Initial Release

Complete refactoring of Windows HardeningKitty for Linux systems using PowerShell Core.

### Features
- Audit mode: Assess system security configuration
- Config mode: Export current configuration
- HailMary mode: Apply hardening automatically with backup
- Support for CIS Rocky Linux 8 & 9 Benchmarks (Level 1 & 2)
- PowerShell Core 7+ compatibility
- Native Linux tool integration (sysctl, systemctl, auditd, firewalld, etc.)
- Comprehensive logging and reporting
- Scoring system (1.0 - 6.0 scale)
- Filtering capabilities (by ID, category, severity)

### Supported Systems
- Rocky Linux 8.x, 9.x
- RHEL 8.x, 9.x
- AlmaLinux 8.x, 9.x
- CentOS Stream 8, 9

### Configuration Methods
- sysctl: Kernel parameters
- config_file: Configuration files (SSH, login.defs, etc.)
- service: systemd services
- package: RPM package management
- permission: File/directory permissions
- mount: Filesystem mount options
- selinux: SELinux configuration
- auditd: Audit rules
- grub: Boot configuration
- modprobe: Kernel modules
- command: Custom shell commands

### Requirements
- PowerShell Core 7.0 or higher
- Root privileges (sudo)
- Rocky Linux or RHEL-based distribution
'@
        }
    }

    # HelpInfo URI of this module
    # HelpInfoURI = ''
}
