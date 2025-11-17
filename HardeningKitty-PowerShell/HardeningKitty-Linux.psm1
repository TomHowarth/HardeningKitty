Function Invoke-HardeningKitty {

    <#
    .SYNOPSIS

        Invoke-HardeningKitty - Checks and hardens your Rocky Linux configuration


         =^._.^=
        _(      )/  HardeningKitty
                    for Linux


        Author:  Refactored for Linux from Windows version by Michael Schneider
        License: MIT
        Required Dependencies: PowerShell Core 7+
        Optional Dependencies: None


    .DESCRIPTION

        HardeningKitty supports hardening of a Rocky Linux (RHEL-based) system. The configuration
        of the system is retrieved and assessed using a finding list. In addition, the system can
        be hardened according to predefined values. HardeningKitty reads settings from sysctl,
        configuration files, systemd, and other Linux system components.


    .PARAMETER FileFindingList

        Path to a finding list in CSV format. HardeningKitty has CIS Benchmark lists for
        Rocky Linux 8 and 9 (Level 1 and Level 2).


    .PARAMETER Mode

        The mode Config only retrieves the settings, while the mode Audit performs an assessment
        of the settings. The mode HailMary hardens the system according to recommendations of the
        HardeningKitty list.


    .PARAMETER EmojiSupport

        The use of emoji is activated. The terminal should support this accordingly.


    .PARAMETER Log

        The logging function is activated. The script output is additionally logged in a file.


    .PARAMETER LogFile

        The name and location of the log file can be defined by the user.


    .PARAMETER Report

        The retrieved settings and their assessment result are stored in CSV format.


    .PARAMETER ReportFile

        The name and location of the report file can be defined by the user.


    .PARAMETER Backup

        Create a backup of current configuration before making changes.


    .PARAMETER BackupFile

        The name and location of the backup file can be defined by the user.


    .PARAMETER SkipSystemInformation

        Information about the system is not queried and displayed.


    .PARAMETER SkipBackup

        Do not create a backup in HailMary mode. NOT RECOMMENDED.


    .PARAMETER Filter

        The Filter parameter can be used to filter the hardening list. For this purpose the
        PowerShell ScriptBlock syntax must be used, for example { $_.ID -eq "1.1.1.1" }.
        The following elements are useful for filtering: ID, Category, Name, Method, and Severity.


    .EXAMPLE
        Invoke-HardeningKitty -Mode Audit -Log -Report

        HardeningKitty performs an audit, saves the results and creates a log file

    .EXAMPLE
        Invoke-HardeningKitty -FileFindingList lists_linux/finding_list_cis_rocky_8_server_l1.csv

        HardeningKitty performs an audit with a specific list

    .EXAMPLE
        Invoke-HardeningKitty -Mode HailMary -Backup

        HardeningKitty hardens the system and creates a backup

    .EXAMPLE
        Invoke-HardeningKitty -Filter { $_.Severity -eq "High" }

        HardeningKitty checks only tests with the severity High
    #>

    [CmdletBinding()]
    Param (

        # Definition of the finding list, default is Rocky Linux 8 Level 1
        [String]
        $FileFindingList,

        # Choose mode, read system config, audit system config, harden system config
        [ValidateSet("Audit", "Config", "HailMary")]
        [String]
        $Mode = "Audit",

        # Activate emoji support
        [Switch]
        $EmojiSupport,

        # Create a log file
        [Switch]
        $Log,

        # Skip system information
        [Switch]
        $SkipSystemInformation,

        # Skip creating a backup during Hail Mary mode
        [Switch]
        $SkipBackup,

        # Define name and path of the log file
        [String]
        $LogFile,

        # Create a report file in CSV format
        [Switch]
        $Report,

        # Define name and path of the report file
        [String]
        $ReportFile,

        # Create a backup file
        [Switch]
        $Backup,

        # Define name and path of the backup file
        [String]
        $BackupFile,

        # Define a filter to reduce the number of tests
        [scriptblock]
        $Filter
    )

    Function Write-ProtocolEntry {
        <#
        .SYNOPSIS
            Output of an event with timestamp and different formatting
            depending on the level.
        #>

        [CmdletBinding()]
        Param (
            [String]
            $Text,

            [String]
            $LogLevel
        )

        $Time = Get-Date -Format G

        Switch ($LogLevel) {
            "Info" { $Message = "[*] $Time - $Text"; Write-Host $Message -ForegroundColor Cyan }
            "Success" { $Message = "[+] $Time - $Text"; Write-Host $Message -ForegroundColor Green }
            "Warning" { $Message = "[!] $Time - $Text"; Write-Host $Message -ForegroundColor Yellow }
            "Error" { $Message = "[X] $Time - $Text"; Write-Host $Message -ForegroundColor Red }
            "Audit" { $Message = "    $Text"; Write-Host $Message }
            Default { $Message = "[*] $Time - $Text"; Write-Host $Message }
        }

        If ($Log -or $LogFile) {
            Add-MessageToFile -Text $Message -File $LogFileFullPath
        }
    }

    Function Add-MessageToFile {
        <#
        .SYNOPSIS
            Write message to a file
        #>

        [CmdletBinding()]
        Param (
            [String]
            $Text,

            [String]
            $File
        )

        try {
            Add-Content -Path $File -Value $Text -ErrorAction Stop
        } catch {
            Write-ProtocolEntry -Text "Error writing to file $File" -LogLevel "Error"
        }
    }

    Function Write-ResultEntry {
        <#
        .SYNOPSIS
            Output of the assessment result with different formatting
        #>

        [CmdletBinding()]
        Param (
            [String]
            $Text,

            [String]
            $SeverityLevel
        )

        If ($EmojiSupport) {
            Switch ($SeverityLevel) {
                "Passed" { $Emoji = [char]::ConvertFromUtf32(0x1F63B); $Message = "[$Emoji] $Text"; Write-Host $Message -ForegroundColor Green }
                "Low" { $Emoji = [char]::ConvertFromUtf32(0x1F63F); $Message = "[$Emoji] $Text"; Write-Host $Message -ForegroundColor Yellow }
                "Medium" { $Emoji = [char]::ConvertFromUtf32(0x1F640); $Message = "[$Emoji] $Text"; Write-Host $Message -ForegroundColor DarkYellow }
                "High" { $Emoji = [char]::ConvertFromUtf32(0x1F63E); $Message = "[$Emoji] $Text"; Write-Host $Message -ForegroundColor Red }
                Default { $Message = "[*] $Text"; Write-Host $Message }
            }
        } Else {
            Switch ($SeverityLevel) {
                "Passed" { $Message = "[+] $Text"; Write-Host $Message -ForegroundColor Green }
                "Low" { $Message = "[!] $Text"; Write-Host $Message -ForegroundColor Yellow }
                "Medium" { $Message = "[!!] $Text"; Write-Host $Message -ForegroundColor DarkYellow }
                "High" { $Message = "[!!!] $Text"; Write-Host $Message -ForegroundColor Red }
                Default { $Message = "[*] $Text"; Write-Host $Message }
            }
        }

        If ($Log -or $LogFile) {
            Add-MessageToFile -Text $Message -File $LogFileFullPath
        }
    }

    Function Get-SysctlValue {
        <#
        .SYNOPSIS
            Get kernel parameter value using sysctl
        #>

        [CmdletBinding()]
        Param (
            [String]
            $Parameter
        )

        try {
            $Result = Invoke-Expression "sysctl -n $Parameter 2>/dev/null"
            return $Result
        } catch {
            return $null
        }
    }

    Function Set-SysctlValue {
        <#
        .SYNOPSIS
            Set kernel parameter value using sysctl
        #>

        [CmdletBinding()]
        Param (
            [String]
            $Parameter,

            [String]
            $Value
        )

        try {
            # Set runtime value
            $null = Invoke-Expression "sysctl -w $Parameter=$Value 2>&1"

            # Persist to file
            $SysctlFile = "/etc/sysctl.d/99-hardeningkitty.conf"

            # Read existing content
            If (Test-Path $SysctlFile) {
                $Content = Get-Content $SysctlFile
            } Else {
                $Content = @()
            }

            # Update or add parameter
            $Found = $false
            $NewContent = @()

            ForEach ($Line in $Content) {
                If ($Line -match "^\s*$Parameter\s*=") {
                    $NewContent += "$Parameter = $Value"
                    $Found = $true
                } Else {
                    $NewContent += $Line
                }
            }

            If (-not $Found) {
                $NewContent += "$Parameter = $Value"
            }

            # Write back
            $NewContent | Set-Content -Path $SysctlFile
            return $true
        } catch {
            return $false
        }
    }

    Function Get-ConfigFileValue {
        <#
        .SYNOPSIS
            Get value from configuration file
        #>

        [CmdletBinding()]
        Param (
            [String]
            $FilePath,

            [String]
            $Key,

            [String]
            $Separator = "="
        )

        try {
            If (-not (Test-Path $FilePath)) {
                return $null
            }

            $Content = Get-Content $FilePath
            ForEach ($Line in $Content) {
                $Line = $Line.Trim()

                # Skip comments and empty lines
                If ($Line -match "^\s*#" -or $Line -match "^\s*$") {
                    continue
                }

                # Check if line contains our key
                If ($Line -match "^\s*$Key\s*$Separator\s*(.*)$") {
                    $Value = $matches[1].Trim().Trim('"').Trim("'")
                    return $Value
                }
            }

            return $null
        } catch {
            return $null
        }
    }

    Function Set-ConfigFileValue {
        <#
        .SYNOPSIS
            Set value in configuration file
        #>

        [CmdletBinding()]
        Param (
            [String]
            $FilePath,

            [String]
            $Key,

            [String]
            $Value,

            [String]
            $Separator = "="
        )

        try {
            # Backup original file
            If (Test-Path $FilePath) {
                $BackupPath = "$FilePath.bak.$(Get-Date -Format 'yyyyMMdd_HHmmss')"
                Copy-Item -Path $FilePath -Destination $BackupPath -Force
            }

            # Read or create content
            If (Test-Path $FilePath) {
                $Content = Get-Content $FilePath
            } Else {
                $Content = @()
            }

            # Update or add key
            $Found = $false
            $NewContent = @()

            ForEach ($Line in $Content) {
                $TrimmedLine = $Line.Trim()

                # Check if this is our key (not commented)
                If ($TrimmedLine -match "^\s*$Key\s*$Separator") {
                    $NewContent += "$Key$Separator$Value"
                    $Found = $true
                } Else {
                    $NewContent += $Line
                }
            }

            If (-not $Found) {
                $NewContent += "$Key$Separator$Value"
            }

            # Write back
            $NewContent | Set-Content -Path $FilePath
            return $true
        } catch {
            return $false
        }
    }

    Function Get-ServiceStatus {
        <#
        .SYNOPSIS
            Get systemd service status
        #>

        [CmdletBinding()]
        Param (
            [String]
            $ServiceName
        )

        try {
            $Result = Invoke-Expression "systemctl is-enabled $ServiceName 2>&1"
            return $Result.Trim()
        } catch {
            return "not-found"
        }
    }

    Function Set-ServiceStatus {
        <#
        .SYNOPSIS
            Set systemd service status
        #>

        [CmdletBinding()]
        Param (
            [String]
            $ServiceName,

            [String]
            $DesiredState
        )

        try {
            Switch ($DesiredState) {
                "enabled" { $null = Invoke-Expression "systemctl enable $ServiceName 2>&1" }
                "disabled" { $null = Invoke-Expression "systemctl disable $ServiceName 2>&1" }
                "masked" { $null = Invoke-Expression "systemctl mask $ServiceName 2>&1" }
                Default { return $false }
            }
            return $true
        } catch {
            return $false
        }
    }

    Function Get-PackageStatus {
        <#
        .SYNOPSIS
            Check if package is installed
        #>

        [CmdletBinding()]
        Param (
            [String]
            $PackageName
        )

        try {
            $Result = Invoke-Expression "rpm -q $PackageName 2>&1"
            If ($Result -match "^package.*is not installed" -or $Result -match "^$PackageName is not installed") {
                return "not-installed"
            }
            return "installed"
        } catch {
            return "not-installed"
        }
    }

    Function Install-Package {
        <#
        .SYNOPSIS
            Install package using dnf/yum
        #>

        [CmdletBinding()]
        Param (
            [String]
            $PackageName
        )

        try {
            $null = Invoke-Expression "dnf install -y $PackageName 2>&1"
            return $true
        } catch {
            return $false
        }
    }

    Function Remove-Package {
        <#
        .SYNOPSIS
            Remove package using dnf/yum
        #>

        [CmdletBinding()]
        Param (
            [String]
            $PackageName
        )

        try {
            $null = Invoke-Expression "dnf remove -y $PackageName 2>&1"
            return $true
        } catch {
            return $false
        }
    }

    Function Get-FilePermission {
        <#
        .SYNOPSIS
            Get file/directory permissions
        #>

        [CmdletBinding()]
        Param (
            [String]
            $Path
        )

        try {
            If (-not (Test-Path $Path)) {
                return $null
            }

            $Result = Invoke-Expression "stat -c '%a' $Path 2>/dev/null"
            return $Result.Trim()
        } catch {
            return $null
        }
    }

    Function Set-FilePermission {
        <#
        .SYNOPSIS
            Set file/directory permissions
        #>

        [CmdletBinding()]
        Param (
            [String]
            $Path,

            [String]
            $Mode
        )

        try {
            If (-not (Test-Path $Path)) {
                return $false
            }

            $null = Invoke-Expression "chmod $Mode $Path 2>&1"
            return $true
        } catch {
            return $false
        }
    }

    Function Get-MountOption {
        <#
        .SYNOPSIS
            Get mount options for filesystem
        #>

        [CmdletBinding()]
        Param (
            [String]
            $MountPoint,

            [String]
            $Option
        )

        try {
            $Result = Invoke-Expression "mount | grep ' on $MountPoint ' 2>/dev/null"

            If ($Result -match '\((.*?)\)') {
                $Options = $matches[1]
                If ($Options -match $Option) {
                    return $Option
                }
            }

            return "missing"
        } catch {
            return "missing"
        }
    }

    Function Get-SELinuxStatus {
        <#
        .SYNOPSIS
            Get SELinux status
        #>

        [CmdletBinding()]
        Param ()

        try {
            $Result = Invoke-Expression "getenforce 2>/dev/null"
            return $Result.Trim().ToLower()
        } catch {
            return "unknown"
        }
    }

    Function Set-SELinuxMode {
        <#
        .SYNOPSIS
            Set SELinux mode
        #>

        [CmdletBinding()]
        Param (
            [String]
            $Mode
        )

        try {
            # Set runtime mode (if not disabled)
            If ($Mode -ne "disabled") {
                $null = Invoke-Expression "setenforce $Mode 2>&1"
            }

            # Update config file for persistence
            $ConfigFile = "/etc/selinux/config"
            Set-ConfigFileValue -FilePath $ConfigFile -Key "SELINUX" -Value $Mode.ToLower()

            return $true
        } catch {
            return $false
        }
    }

    Function Get-AuditRule {
        <#
        .SYNOPSIS
            Check if auditd rule exists
        #>

        [CmdletBinding()]
        Param (
            [String]
            $RulePattern
        )

        try {
            $Result = Invoke-Expression "auditctl -l 2>/dev/null"

            ForEach ($Line in $Result) {
                If ($Line -match $RulePattern) {
                    return "present"
                }
            }

            return "absent"
        } catch {
            return "absent"
        }
    }

    Function Add-AuditRule {
        <#
        .SYNOPSIS
            Add auditd rule
        #>

        [CmdletBinding()]
        Param (
            [String]
            $Rule
        )

        try {
            # Add to runtime
            $null = Invoke-Expression "auditctl -a $Rule 2>&1"

            # Persist to rules file
            $RulesFile = "/etc/audit/rules.d/hardeningkitty.rules"
            $Content = ""

            If (Test-Path $RulesFile) {
                $Content = Get-Content $RulesFile -Raw
            }

            # Check if rule already exists
            If ($Content -notmatch [regex]::Escape($Rule)) {
                Add-Content -Path $RulesFile -Value "-a $Rule"
            }

            return $true
        } catch {
            return $false
        }
    }

    Function Get-ModprobeStatus {
        <#
        .SYNOPSIS
            Check if kernel module is blacklisted
        #>

        [CmdletBinding()]
        Param (
            [String]
            $Module
        )

        try {
            $BlacklistFiles = @(
                "/etc/modprobe.d/blacklist.conf",
                "/etc/modprobe.d/hardeningkitty.conf"
            )

            ForEach ($File in $BlacklistFiles) {
                If (Test-Path $File) {
                    $Content = Get-Content $File -Raw
                    If ($Content -match "blacklist\s+$Module") {
                        return "blacklisted"
                    }
                }
            }

            # Check if module is loaded
            $Result = Invoke-Expression "lsmod | grep $Module 2>/dev/null"
            If ($Result) {
                return "loaded"
            }

            return "not-loaded"
        } catch {
            return "unknown"
        }
    }

    Function Set-ModprobeBlacklist {
        <#
        .SYNOPSIS
            Blacklist kernel module
        #>

        [CmdletBinding()]
        Param (
            [String]
            $Module
        )

        try {
            $ModprobeFile = "/etc/modprobe.d/hardeningkitty.conf"
            $Content = ""

            If (Test-Path $ModprobeFile) {
                $Content = Get-Content $ModprobeFile -Raw
            }

            If ($Content -notmatch "blacklist\s+$Module") {
                $Entry = @"

blacklist $Module
install $Module /bin/true
"@
                Add-Content -Path $ModprobeFile -Value $Entry
            }

            return $true
        } catch {
            return $false
        }
    }

    Function Get-GrubParameter {
        <#
        .SYNOPSIS
            Get GRUB kernel parameter
        #>

        [CmdletBinding()]
        Param (
            [String]
            $Parameter
        )

        try {
            $GrubFile = "/etc/default/grub"

            If (-not (Test-Path $GrubFile)) {
                return $null
            }

            $Content = Get-Content $GrubFile
            ForEach ($Line in $Content) {
                If ($Line -match 'GRUB_CMDLINE_LINUX="(.*?)"') {
                    $CmdLine = $matches[1]

                    # Look for specific parameter
                    ForEach ($Item in $CmdLine.Split()) {
                        If ($Item -match "^$Parameter=(.+)$") {
                            return $matches[1]
                        } ElseIf ($Item -eq $Parameter) {
                            return "present"
                        }
                    }
                }
            }

            return $null
        } catch {
            return $null
        }
    }

    Function Set-GrubParameter {
        <#
        .SYNOPSIS
            Set GRUB kernel parameter
        #>

        [CmdletBinding()]
        Param (
            [String]
            $Parameter,

            [String]
            $Value
        )

        try {
            $GrubFile = "/etc/default/grub"

            # Backup original file
            If (Test-Path $GrubFile) {
                $BackupPath = "$GrubFile.bak.$(Get-Date -Format 'yyyyMMdd_HHmmss')"
                Copy-Item -Path $GrubFile -Destination $BackupPath -Force
            }

            $Content = Get-Content $GrubFile
            $NewContent = @()

            ForEach ($Line in $Content) {
                If ($Line -match 'GRUB_CMDLINE_LINUX="(.*?)"') {
                    $CmdLine = $matches[1]

                    # Remove existing parameter
                    $Params = @()
                    ForEach ($Item in $CmdLine.Split()) {
                        If (-not ($Item -match "^$Parameter=" -or $Item -eq $Parameter)) {
                            $Params += $Item
                        }
                    }

                    # Add new parameter
                    If ($Value) {
                        $Params += "$Parameter=$Value"
                    } Else {
                        $Params += $Parameter
                    }

                    $NewCmdLine = $Params -join ' '
                    $NewContent += "GRUB_CMDLINE_LINUX=`"$NewCmdLine`""
                } Else {
                    $NewContent += $Line
                }
            }

            # Write updated configuration
            $NewContent | Set-Content -Path $GrubFile

            # Rebuild GRUB configuration
            $null = Invoke-Expression "grub2-mkconfig -o /boot/grub2/grub.cfg 2>&1"

            return $true
        } catch {
            return $false
        }
    }

    Function Get-CurrentValue {
        <#
        .SYNOPSIS
            Get current value based on finding method
        #>

        [CmdletBinding()]
        Param (
            [Hashtable]
            $Finding
        )

        $Method = $Finding.Method
        $MethodArgument = $Finding.MethodArgument
        $ConfigPath = $Finding.ConfigPath
        $ConfigKey = $Finding.ConfigKey

        try {
            Switch ($Method) {
                "sysctl" {
                    return Get-SysctlValue -Parameter $MethodArgument
                }
                "config_file" {
                    return Get-ConfigFileValue -FilePath $ConfigPath -Key $ConfigKey
                }
                "service" {
                    return Get-ServiceStatus -ServiceName $MethodArgument
                }
                "package" {
                    return Get-PackageStatus -PackageName $MethodArgument
                }
                "permission" {
                    return Get-FilePermission -Path $ConfigPath
                }
                "mount" {
                    return Get-MountOption -MountPoint $ConfigPath -Option $MethodArgument
                }
                "selinux" {
                    return Get-SELinuxStatus
                }
                "auditd" {
                    return Get-AuditRule -RulePattern $MethodArgument
                }
                "grub" {
                    return Get-GrubParameter -Parameter $MethodArgument
                }
                "modprobe" {
                    return Get-ModprobeStatus -Module $MethodArgument
                }
                "file_exists" {
                    If (Test-Path $ConfigPath) {
                        return "exists"
                    } Else {
                        return "not-exists"
                    }
                }
                "command" {
                    $Result = Invoke-Expression "$MethodArgument 2>/dev/null"
                    return $Result
                }
                Default {
                    return "unknown_method:$Method"
                }
            }
        } catch {
            return $null
        }
    }

    Function Set-HardenedValue {
        <#
        .SYNOPSIS
            Apply hardened value based on finding method
        #>

        [CmdletBinding()]
        Param (
            [Hashtable]
            $Finding
        )

        $Method = $Finding.Method
        $MethodArgument = $Finding.MethodArgument
        $ConfigPath = $Finding.ConfigPath
        $ConfigKey = $Finding.ConfigKey
        $RecommendedValue = $Finding.RecommendedValue

        try {
            Switch ($Method) {
                "sysctl" {
                    return Set-SysctlValue -Parameter $MethodArgument -Value $RecommendedValue
                }
                "config_file" {
                    return Set-ConfigFileValue -FilePath $ConfigPath -Key $ConfigKey -Value $RecommendedValue
                }
                "service" {
                    return Set-ServiceStatus -ServiceName $MethodArgument -DesiredState $RecommendedValue
                }
                "package" {
                    If ($RecommendedValue -eq "not-installed") {
                        return Remove-Package -PackageName $MethodArgument
                    } ElseIf ($RecommendedValue -eq "installed") {
                        return Install-Package -PackageName $MethodArgument
                    }
                    return $false
                }
                "permission" {
                    return Set-FilePermission -Path $ConfigPath -Mode $RecommendedValue
                }
                "selinux" {
                    return Set-SELinuxMode -Mode $RecommendedValue
                }
                "auditd" {
                    If ($RecommendedValue -match "present|enabled") {
                        return Add-AuditRule -Rule $MethodArgument
                    }
                    return $true
                }
                "grub" {
                    return Set-GrubParameter -Parameter $MethodArgument -Value $RecommendedValue
                }
                "modprobe" {
                    If ($RecommendedValue -match "blacklisted|disabled") {
                        return Set-ModprobeBlacklist -Module $MethodArgument
                    }
                    return $true
                }
                Default {
                    Write-ProtocolEntry -Text "Unknown method: $Method" -LogLevel "Warning"
                    return $false
                }
            }
        } catch {
            return $false
        }
    }

    Function Compare-Values {
        <#
        .SYNOPSIS
            Compare current and expected values using operator
        #>

        [CmdletBinding()]
        Param (
            [String]
            $Current,

            [String]
            $Expected,

            [String]
            $Operator
        )

        # Handle null/empty values
        If ([string]::IsNullOrEmpty($Current)) {
            $Current = ""
        }
        If ([string]::IsNullOrEmpty($Expected)) {
            $Expected = ""
        }

        try {
            Switch ($Operator) {
                "=" {
                    return $Current -eq $Expected
                }
                "!=" {
                    return $Current -ne $Expected
                }
                "contains" {
                    return $Current -like "*$Expected*"
                }
                "=|0" {
                    return ($Current -eq $Expected) -or ($Current -eq "0") -or ($Current -eq "")
                }
                "<=" {
                    return [int]$Current -le [int]$Expected
                }
                ">=" {
                    return [int]$Current -ge [int]$Expected
                }
                "<=!0" {
                    $IntCurrent = [int]$Current
                    return ($IntCurrent -le [int]$Expected) -and ($IntCurrent -ne 0)
                }
                Default {
                    Write-ProtocolEntry -Text "Unknown operator: $Operator" -LogLevel "Warning"
                    return $false
                }
            }
        } catch {
            # If numeric comparison fails, fall back to string comparison
            If ($Operator -match "<=|>=|<=!0") {
                return $false
            }
            return $Current -eq $Expected
        }
    }

    #
    # Main Script
    #

    # Set TLS to 1.2 for compatibility (if needed for any web operations)
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

    # Define default finding list path
    $ScriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
    If ($FileFindingList -eq "") {
        $FileFindingList = Join-Path $ScriptPath "lists_linux/finding_list_cis_rocky_8_server_l1.csv"
    }

    # Check if running as root
    $CurrentUser = Invoke-Expression "whoami"
    If ($CurrentUser -ne "root") {
        Write-ProtocolEntry -Text "This script must be run as root (use sudo)" -LogLevel "Error"
        return
    }

    # Setup log file
    If ($Log -or $LogFile) {
        If ($LogFile) {
            $LogFileFullPath = $LogFile
        } Else {
            $Timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
            $LogFileFullPath = Join-Path $ScriptPath "hardeningkitty_log_$Timestamp.log"
        }
        Write-ProtocolEntry -Text "Log file: $LogFileFullPath" -LogLevel "Info"
    }

    # Setup report file
    If ($Report -or $ReportFile) {
        If ($ReportFile) {
            $ReportFileFullPath = $ReportFile
        } Else {
            $Timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
            $ReportFileFullPath = Join-Path $ScriptPath "hardeningkitty_report_$Timestamp.csv"
        }
    }

    # Setup backup file
    If (($Backup -or $BackupFile) -and $Mode -eq "Config") {
        If ($BackupFile) {
            $BackupFileFullPath = $BackupFile
        } Else {
            $Timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
            $BackupFileFullPath = Join-Path $ScriptPath "hardeningkitty_backup_$Timestamp.csv"
        }
    }

    #
    # Header
    #
    Write-Output ""
    Write-Output "     =^._.^="
    Write-Output "    _(      )/  HardeningKitty for Linux"
    Write-Output ""
    Write-ProtocolEntry -Text "Starting HardeningKitty" -LogLevel "Info"
    Write-Output ""

    #
    # System Information
    #
    If (-not $SkipSystemInformation) {
        Write-Output ""
        Write-ProtocolEntry -Text "Getting system information" -LogLevel "Info"

        $Hostname = Invoke-Expression "hostname"
        $OSRelease = Invoke-Expression "cat /etc/os-release | grep PRETTY_NAME | cut -d'=' -f2 | tr -d '\"'"
        $KernelVersion = Invoke-Expression "uname -r"
        $Uptime = Invoke-Expression "uptime -p"

        Write-ProtocolEntry -Text "Hostname: $Hostname" -LogLevel "Info"
        Write-ProtocolEntry -Text "OS: $OSRelease" -LogLevel "Info"
        Write-ProtocolEntry -Text "Kernel: $KernelVersion" -LogLevel "Info"
        Write-ProtocolEntry -Text "Uptime: $Uptime" -LogLevel "Info"
        Write-Output ""
    }

    #
    # Load Finding List
    #
    Write-ProtocolEntry -Text "Loading finding list: $FileFindingList" -LogLevel "Info"

    If (-not (Test-Path $FileFindingList)) {
        Write-ProtocolEntry -Text "Finding list not found: $FileFindingList" -LogLevel "Error"
        return
    }

    try {
        $FindingList = Import-Csv -Path $FileFindingList -Delimiter ","
    } catch {
        Write-ProtocolEntry -Text "Failed to load finding list: $_" -LogLevel "Error"
        return
    }

    # Apply filter if specified
    If ($Filter) {
        $FindingList = $FindingList | Where-Object $Filter
    }

    Write-ProtocolEntry -Text "Loaded $($FindingList.Count) findings" -LogLevel "Success"
    Write-Output ""

    #
    # Initialize Results
    #
    $Results = @()
    $StatsTotal = 0
    $StatsPassed = 0
    $StatsLow = 0
    $StatsMedium = 0
    $StatsHigh = 0
    $StatsError = 0

    #
    # Process Findings
    #
    Switch ($Mode) {
        "Audit" {
            Write-ProtocolEntry -Text "Starting audit mode" -LogLevel "Info"
            Write-Output ""

            ForEach ($Finding in $FindingList) {
                $StatsTotal++

                # Get current value
                $CurrentValue = Get-CurrentValue -Finding $Finding

                # Create result object
                $Result = [PSCustomObject]@{
                    ID = $Finding.ID
                    Category = $Finding.Category
                    Name = $Finding.Name
                    Method = $Finding.Method
                    Severity = $Finding.Severity
                    CurrentValue = $CurrentValue
                    RecommendedValue = $Finding.RecommendedValue
                    Operator = $Finding.Operator
                    TestResult = ""
                    Message = ""
                }

                # Compare values
                If ($null -eq $CurrentValue) {
                    $Result.TestResult = "Error"
                    $Result.Message = "Could not retrieve value"
                    $StatsError++
                } Else {
                    $Matches = Compare-Values -Current $CurrentValue -Expected $Finding.RecommendedValue -Operator $Finding.Operator

                    If ($Matches) {
                        $Result.TestResult = "Passed"
                        $StatsPassed++
                    } Else {
                        $Result.TestResult = $Finding.Severity
                        Switch ($Finding.Severity) {
                            "Low" { $StatsLow++ }
                            "Medium" { $StatsMedium++ }
                            "High" { $StatsHigh++ }
                        }
                    }
                }

                # Display result
                $ResultText = "$($Result.ID) - $($Result.Name): $CurrentValue (Expected: $($Finding.RecommendedValue))"
                Write-ResultEntry -Text $ResultText -SeverityLevel $Result.TestResult

                # Add to results
                $Results += $Result
            }
        }

        "Config" {
            Write-ProtocolEntry -Text "Starting config mode" -LogLevel "Info"
            Write-Output ""

            ForEach ($Finding in $FindingList) {
                # Get current value
                $CurrentValue = Get-CurrentValue -Finding $Finding

                # Create result object
                $Result = [PSCustomObject]@{
                    ID = $Finding.ID
                    Category = $Finding.Category
                    Name = $Finding.Name
                    Method = $Finding.Method
                    CurrentValue = $CurrentValue
                    RecommendedValue = $Finding.RecommendedValue
                }

                # Display result
                Write-ProtocolEntry -Text "$($Result.ID) - $($Result.Name): $CurrentValue" -LogLevel "Audit"

                # Add to results
                $Results += $Result
            }
        }

        "HailMary" {
            Write-ProtocolEntry -Text "Starting HailMary mode - System will be hardened!" -LogLevel "Warning"
            Write-Output ""

            # Create backup if not skipped
            If (-not $SkipBackup) {
                Write-ProtocolEntry -Text "Creating backup before changes..." -LogLevel "Info"

                $BackupData = @()
                ForEach ($Finding in $FindingList) {
                    $CurrentValue = Get-CurrentValue -Finding $Finding
                    $BackupData += [PSCustomObject]@{
                        ID = $Finding.ID
                        Name = $Finding.Name
                        Method = $Finding.Method
                        MethodArgument = $Finding.MethodArgument
                        ConfigPath = $Finding.ConfigPath
                        ConfigKey = $Finding.ConfigKey
                        CurrentValue = $CurrentValue
                        RecommendedValue = $Finding.RecommendedValue
                    }
                }

                If ($BackupFile) {
                    $BackupFileFullPath = $BackupFile
                } Else {
                    $Timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
                    $BackupFileFullPath = Join-Path $ScriptPath "hardeningkitty_backup_$Timestamp.csv"
                }

                $BackupData | Export-Csv -Path $BackupFileFullPath -NoTypeInformation
                Write-ProtocolEntry -Text "Backup saved to: $BackupFileFullPath" -LogLevel "Success"
                Write-Output ""
            }

            # Apply hardening
            Write-ProtocolEntry -Text "Applying hardening settings..." -LogLevel "Info"
            Write-Output ""

            ForEach ($Finding in $FindingList) {
                $StatsTotal++

                # Apply setting
                $Applied = Set-HardenedValue -Finding $Finding

                # Create result object
                $Result = [PSCustomObject]@{
                    ID = $Finding.ID
                    Category = $Finding.Category
                    Name = $Finding.Name
                    Method = $Finding.Method
                    RecommendedValue = $Finding.RecommendedValue
                    Applied = $Applied
                }

                # Display result
                If ($Applied) {
                    Write-ProtocolEntry -Text "$($Result.ID) - $($Result.Name): Applied" -LogLevel "Success"
                    $StatsPassed++
                } Else {
                    Write-ProtocolEntry -Text "$($Result.ID) - $($Result.Name): Failed" -LogLevel "Error"
                    $StatsError++
                }

                # Add to results
                $Results += $Result
            }
        }
    }

    #
    # Summary
    #
    Write-Output ""
    Write-Output ""
    Write-ProtocolEntry -Text "=== Summary ===" -LogLevel "Info"
    Write-Output ""

    If ($Mode -eq "Audit") {
        Write-ProtocolEntry -Text "Total checks: $StatsTotal" -LogLevel "Info"
        Write-ProtocolEntry -Text "Passed: $StatsPassed" -LogLevel "Success"
        Write-ProtocolEntry -Text "Low: $StatsLow" -LogLevel "Warning"
        Write-ProtocolEntry -Text "Medium: $StatsMedium" -LogLevel "Warning"
        Write-ProtocolEntry -Text "High: $StatsHigh" -LogLevel "Error"
        If ($StatsError -gt 0) {
            Write-ProtocolEntry -Text "Errors: $StatsError" -LogLevel "Error"
        }

        # Calculate score
        $MaxPoints = $StatsTotal * 4
        $AchievedPoints = ($StatsPassed * 4) + ($StatsLow * 2) + ($StatsMedium * 1)

        If ($MaxPoints -gt 0) {
            $Score = ($AchievedPoints / $MaxPoints) * 5 + 1
        } Else {
            $Score = 1.0
        }

        Write-Output ""
        Write-ProtocolEntry -Text "HardeningKitty Score: $($Score.ToString('0.00')) / 6.0" -LogLevel "Info"
    } ElseIf ($Mode -eq "Config") {
        Write-ProtocolEntry -Text "Configuration exported for $($Results.Count) settings" -LogLevel "Info"
    } ElseIf ($Mode -eq "HailMary") {
        Write-ProtocolEntry -Text "Total settings: $StatsTotal" -LogLevel "Info"
        Write-ProtocolEntry -Text "Applied: $StatsPassed" -LogLevel "Success"
        If ($StatsError -gt 0) {
            Write-ProtocolEntry -Text "Failed: $StatsError" -LogLevel "Error"
        }
        Write-Output ""
        Write-ProtocolEntry -Text "Hardening complete. Please review changes and reboot if necessary." -LogLevel "Warning"
    }

    #
    # Save Report
    #
    If (($Report -or $ReportFile) -and $Results.Count -gt 0) {
        Write-Output ""
        Write-ProtocolEntry -Text "Saving report to: $ReportFileFullPath" -LogLevel "Info"

        try {
            $Results | Export-Csv -Path $ReportFileFullPath -NoTypeInformation
            Write-ProtocolEntry -Text "Report saved successfully" -LogLevel "Success"
        } catch {
            Write-ProtocolEntry -Text "Failed to save report: $_" -LogLevel "Error"
        }
    }

    #
    # Save Config Backup
    #
    If ($Backup -and $Mode -eq "Config" -and $Results.Count -gt 0) {
        Write-Output ""
        Write-ProtocolEntry -Text "Saving backup to: $BackupFileFullPath" -LogLevel "Info"

        try {
            $Results | Export-Csv -Path $BackupFileFullPath -NoTypeInformation
            Write-ProtocolEntry -Text "Backup saved successfully" -LogLevel "Success"
        } catch {
            Write-ProtocolEntry -Text "Failed to save backup: $_" -LogLevel "Error"
        }
    }

    Write-Output ""
    Write-ProtocolEntry -Text "HardeningKitty completed" -LogLevel "Success"
    Write-Output ""
}

# Export the function
Export-ModuleMember -Function Invoke-HardeningKitty
