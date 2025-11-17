#!/usr/bin/pwsh
<#
.SYNOPSIS
    HardeningKitty for Linux - Apply Hardening Example

.DESCRIPTION
    This script applies CIS Level 1 hardening with automatic backup

.NOTES
    Requires: PowerShell Core 7+, root privileges
    WARNING: This will modify your system configuration!
#>

# Check if running as root
if ((Invoke-Expression "whoami") -ne "root") {
    Write-Error "This script must be run as root (use sudo)"
    exit 1
}

# Get script directory
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$ModulePath = Join-Path (Split-Path -Parent $ScriptDir) "HardeningKitty-Linux.psm1"

# Import module
Write-Host "Importing HardeningKitty module..." -ForegroundColor Cyan
Import-Module $ModulePath -Force

# Create directories
$BackupsDir = Join-Path (Split-Path -Parent $ScriptDir) "backups"
$ReportsDir = Join-Path (Split-Path -Parent $ScriptDir) "reports"

if (-not (Test-Path $BackupsDir)) {
    New-Item -ItemType Directory -Path $BackupsDir | Out-Null
}

if (-not (Test-Path $ReportsDir)) {
    New-Item -ItemType Directory -Path $ReportsDir | Out-Null
}

# Generate timestamp
$Timestamp = Get-Date -Format "yyyyMMdd_HHmmss"

# Display warning
Write-Host ""
Write-Host "==================================================================" -ForegroundColor Red
Write-Host "HardeningKitty for Linux - Apply Hardening" -ForegroundColor Red
Write-Host "WARNING: This will modify your system configuration!" -ForegroundColor Red
Write-Host "==================================================================" -ForegroundColor Red
Write-Host ""

# Confirm action
$Confirmation = Read-Host "Are you sure you want to proceed? (yes/no)"

if ($Confirmation -ne "yes") {
    Write-Host "Operation cancelled." -ForegroundColor Yellow
    exit 0
}

# Run hardening
Write-Host ""
Write-Host "Applying CIS Level 1 hardening..." -ForegroundColor Cyan
Write-Host ""

Invoke-HardeningKitty `
    -Mode HailMary `
    -Backup `
    -BackupFile (Join-Path $BackupsDir "backup_$Timestamp.csv") `
    -Report `
    -ReportFile (Join-Path $ReportsDir "hardening_report_$Timestamp.csv") `
    -Log `
    -LogFile (Join-Path $ReportsDir "hardening_log_$Timestamp.log")

Write-Host ""
Write-Host "==================================================================" -ForegroundColor Green
Write-Host "Hardening complete!" -ForegroundColor Green
Write-Host "Backup: backups/backup_$Timestamp.csv" -ForegroundColor Yellow
Write-Host "Report: reports/hardening_report_$Timestamp.csv" -ForegroundColor Yellow
Write-Host "Log: reports/hardening_log_$Timestamp.log" -ForegroundColor Yellow
Write-Host ""
Write-Host "IMPORTANT: Review the changes and reboot the system if necessary." -ForegroundColor Red
Write-Host "==================================================================" -ForegroundColor Green
