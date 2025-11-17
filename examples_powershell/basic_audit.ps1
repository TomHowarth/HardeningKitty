#!/usr/bin/pwsh
<#
.SYNOPSIS
    HardeningKitty for Linux - Basic Audit Example

.DESCRIPTION
    This script performs a basic security audit using CIS Level 1 benchmark

.NOTES
    Requires: PowerShell Core 7+, root privileges
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

# Create reports directory
$ReportsDir = Join-Path (Split-Path -Parent $ScriptDir) "reports"
if (-not (Test-Path $ReportsDir)) {
    New-Item -ItemType Directory -Path $ReportsDir | Out-Null
}

# Generate timestamp
$Timestamp = Get-Date -Format "yyyyMMdd_HHmmss"

# Run audit
Write-Host ""
Write-Host "==================================================================" -ForegroundColor Cyan
Write-Host "HardeningKitty for Linux - Basic Audit" -ForegroundColor Cyan
Write-Host "==================================================================" -ForegroundColor Cyan
Write-Host ""

Invoke-HardeningKitty `
    -Mode Audit `
    -Report `
    -ReportFile (Join-Path $ReportsDir "audit_report_$Timestamp.csv") `
    -Log `
    -LogFile (Join-Path $ReportsDir "audit_log_$Timestamp.log") `
    -EmojiSupport

Write-Host ""
Write-Host "==================================================================" -ForegroundColor Cyan
Write-Host "Audit complete!" -ForegroundColor Green
Write-Host "Report: reports/audit_report_$Timestamp.csv" -ForegroundColor Yellow
Write-Host "Log: reports/audit_log_$Timestamp.log" -ForegroundColor Yellow
Write-Host "==================================================================" -ForegroundColor Cyan
