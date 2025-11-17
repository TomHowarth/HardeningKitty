#!/bin/bash
#
# HardeningKitty-Linux - Audit High Severity Issues Only
# This script checks only high-severity security findings
#

echo "==================================================================="
echo "HardeningKitty-Linux - High Severity Audit"
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

# Run audit for high severity only
echo "Running high severity security audit..."
python3 hardeningkitty.py \
    --mode audit \
    --finding-list lists_linux/finding_list_cis_rocky_8_server_l1.csv \
    --filter-severity High \
    --report "reports/high_severity_${TIMESTAMP}.csv" \
    --log "reports/high_severity_${TIMESTAMP}.log" \
    --emoji \
    --verbose

echo ""
echo "==================================================================="
echo "High severity audit complete!"
echo "Report saved to: reports/high_severity_${TIMESTAMP}.csv"
echo "Log saved to: reports/high_severity_${TIMESTAMP}.log"
echo "==================================================================="
