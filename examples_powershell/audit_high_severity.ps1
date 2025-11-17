#!/usr/bin/pwsh
<#
.SYNOPSIS
    HardeningKitty for Linux - High Severity Audit

.DESCRIPTION
    This script checks only high-severity security findings

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

# Run high severity audit
Write-Host ""
Write-Host "==================================================================" -ForegroundColor Cyan
Write-Host "HardeningKitty for Linux - High Severity Audit" -ForegroundColor Cyan
Write-Host "==================================================================" -ForegroundColor Cyan
Write-Host ""

Invoke-HardeningKitty `
    -Mode Audit `
    -Filter { $_.Severity -eq "High" } `
    -Report `
    -ReportFile (Join-Path $ReportsDir "high_severity_$Timestamp.csv") `
    -Log `
    -LogFile (Join-Path $ReportsDir "high_severity_$Timestamp.log") `
    -EmojiSupport

Write-Host ""
Write-Host "==================================================================" -ForegroundColor Cyan
Write-Host "High severity audit complete!" -ForegroundColor Green
Write-Host "Report: reports/high_severity_$Timestamp.csv" -ForegroundColor Yellow
Write-Host "Log: reports/high_severity_$Timestamp.log" -ForegroundColor Yellow
Write-Host "==================================================================" -ForegroundColor Cyan
