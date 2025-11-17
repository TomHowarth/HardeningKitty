#!/usr/bin/pwsh
<#
.SYNOPSIS
    HardeningKitty for Linux - Incremental Hardening

.DESCRIPTION
    This script applies hardening category by category with user confirmation

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

# Define categories in recommended order
$Categories = @(
    "Initial Setup",
    "Services",
    "Network Configuration",
    "Logging and Auditing",
    "Access Authentication Authorization",
    "System Maintenance"
)

Write-Host ""
Write-Host "==================================================================" -ForegroundColor Cyan
Write-Host "HardeningKitty for Linux - Incremental Hardening" -ForegroundColor Cyan
Write-Host "==================================================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "This script will apply hardening category by category." -ForegroundColor Yellow
Write-Host "You will be prompted before each category." -ForegroundColor Yellow
Write-Host ""

$TotalCategories = $Categories.Count
$CurrentCategory = 0

foreach ($Category in $Categories) {
    $CurrentCategory++

    Write-Host ""
    Write-Host "==================================================================" -ForegroundColor Magenta
    Write-Host "[$CurrentCategory/$TotalCategories] Category: $Category" -ForegroundColor Magenta
    Write-Host "==================================================================" -ForegroundColor Magenta
    Write-Host ""

    # Show what will be hardened
    Write-Host "Checking findings in this category..." -ForegroundColor Cyan

    $FindingList = Import-Csv -Path (Join-Path (Split-Path -Parent $ScriptDir) "lists_linux/finding_list_cis_rocky_8_server_l1.csv")
    $CategoryFindings = $FindingList | Where-Object { $_.Category -eq $Category }

    Write-Host "Found $($CategoryFindings.Count) findings in this category:" -ForegroundColor Yellow
    $CategoryFindings | Select-Object -First 5 | ForEach-Object {
        Write-Host "  - $($_.ID): $($_.Name)" -ForegroundColor Gray
    }

    if ($CategoryFindings.Count -gt 5) {
        Write-Host "  ... and $($CategoryFindings.Count - 5) more" -ForegroundColor Gray
    }

    Write-Host ""

    # Confirm action
    $Confirmation = Read-Host "Apply hardening for this category? (yes/no/quit)"

    if ($Confirmation -eq "quit") {
        Write-Host "Exiting..." -ForegroundColor Yellow
        break
    }

    if ($Confirmation -ne "yes") {
        Write-Host "Skipping category: $Category" -ForegroundColor Yellow
        continue
    }

    # Apply hardening
    $Timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
    $CategorySafe = $Category -replace ' ','_'

    Write-Host ""
    Write-Host "Applying hardening for: $Category" -ForegroundColor Green
    Write-Host ""

    Invoke-HardeningKitty `
        -Mode HailMary `
        -Filter { $_.Category -eq $Category } `
        -Backup `
        -BackupFile (Join-Path $BackupsDir "backup_${Timestamp}_${CategorySafe}.csv") `
        -Log `
        -LogFile (Join-Path $ReportsDir "hardening_${Timestamp}_${CategorySafe}.log") `
        -SkipSystemInformation

    Write-Host ""
    Write-Host "Category '$Category' completed!" -ForegroundColor Green
    Write-Host "Backup: backups/backup_${Timestamp}_${CategorySafe}.csv" -ForegroundColor Yellow
    Write-Host ""

    if ($CurrentCategory -lt $TotalCategories) {
        Write-Host "Press Enter to continue to next category..."
        Read-Host
    }
}

Write-Host ""
Write-Host "==================================================================" -ForegroundColor Green
Write-Host "Incremental hardening completed!" -ForegroundColor Green
Write-Host ""
Write-Host "Categories processed: $CurrentCategory / $TotalCategories" -ForegroundColor Yellow
Write-Host ""
Write-Host "IMPORTANT: Review changes and reboot if necessary." -ForegroundColor Red
Write-Host "==================================================================" -ForegroundColor Green
