#!/usr/bin/env bash
# Web Server Log Analyzer
# Analyzes web server logs for 404 errors, most requested pages, and top IP addresses
# Usage: ./log_analyzer.sh <log_file>

# Enable strict error handling
set -o errexit
set -o nounset
set -o pipefail

# Check if log file argument is provided
if [ $# -lt 1 ]; then
  echo "Usage: $0 <log_file>"
  exit 2
fi

LOG_FILE="$1"

# Verify log file exists
if [ ! -f "$LOG_FILE" ]; then
  echo "Error: Log file '$LOG_FILE' not found"
  exit 1
fi

# Generate timestamp for the report
timestamp() { date "+%Y-%m-%d %H:%M:%S"; }

echo "LOG ANALYSIS REPORT - $(timestamp)"
echo "Log file: $LOG_FILE"
echo ""

# Count 404 errors as requested
echo "404 ERRORS:"
four_oh_four_count=$(grep -c ' 404 ' "$LOG_FILE" 2>/dev/null || echo "0")
echo "Total 404 errors found: $four_oh_four_count"
echo ""

# Find most requested pages as requested
echo "MOST REQUESTED PAGES:"
awk '{print $7}' "$LOG_FILE" | sort | uniq -c | sort -rn | head -10 | while read count page; do
  echo "$page - $count requests"
done
echo ""

# Find IP addresses with most requests as requested
echo "IP ADDRESSES WITH MOST REQUESTS:"
awk '{print $1}' "$LOG_FILE" | sort | uniq -c | sort -rn | head -10 | while read count ip; do
  echo "$ip - $count requests"
done
