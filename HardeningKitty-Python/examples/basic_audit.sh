#!/bin/bash
#
# HardeningKitty-Linux - Basic Audit Example
# This script performs a basic security audit
#

echo "==================================================================="
echo "HardeningKitty-Linux - Basic Audit"
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

# Create reports directory
mkdir -p reports
TIMESTAMP=$(date +%Y%m%d_%H%M%S)

# Run audit
echo "Running security audit..."
python3 hardeningkitty.py \
    --mode audit \
    --finding-list lists_linux/finding_list_cis_rocky_8_server_l1.csv \
    --report "reports/audit_report_${TIMESTAMP}.csv" \
    --log "reports/audit_log_${TIMESTAMP}.log" \
    --emoji \
    --verbose

echo ""
echo "==================================================================="
echo "Audit complete!"
echo "Report saved to: reports/audit_report_${TIMESTAMP}.csv"
echo "Log saved to: reports/audit_log_${TIMESTAMP}.log"
echo "==================================================================="
