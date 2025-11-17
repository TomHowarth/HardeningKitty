#!/bin/bash
#
# HardeningKitty-Linux - Apply Hardening Example
# This script applies CIS Level 1 hardening with automatic backup
#

echo "==================================================================="
echo "HardeningKitty-Linux - Apply Hardening"
echo "WARNING: This will modify your system configuration!"
echo "==================================================================="
echo ""

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    echo "ERROR: This script must be run as root (use sudo)"
    exit 1
fi

# Navigate to HardeningKitty directory
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
HKITTY_DIR="$(dirname "$SCRIPT_DIR")"

cd "$HKITTY_DIR" || exit 1

# Create backups and reports directories
mkdir -p backups reports
TIMESTAMP=$(date +%Y%m%d_%H%M%S)

# Confirm action
read -p "Are you sure you want to apply hardening? (yes/no): " CONFIRM

if [ "$CONFIRM" != "yes" ]; then
    echo "Operation cancelled."
    exit 0
fi

# Run hardening
echo ""
echo "Applying CIS Level 1 hardening..."
python3 hardeningkitty.py \
    --mode hailmary \
    --finding-list lists_linux/finding_list_cis_rocky_8_server_l1.csv \
    --backup \
    --backup-file "backups/backup_${TIMESTAMP}.json" \
    --report "reports/hardening_report_${TIMESTAMP}.csv" \
    --log "reports/hardening_log_${TIMESTAMP}.log"

echo ""
echo "==================================================================="
echo "Hardening complete!"
echo "Backup saved to: backups/backup_${TIMESTAMP}.json"
echo "Report saved to: reports/hardening_report_${TIMESTAMP}.csv"
echo "Log saved to: reports/hardening_log_${TIMESTAMP}.log"
echo ""
echo "IMPORTANT: Review the changes and reboot the system if necessary."
echo "==================================================================="
