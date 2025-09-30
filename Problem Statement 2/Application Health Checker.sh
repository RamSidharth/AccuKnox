#!/usr/bin/env bash


# Handling all the errors
set -o errexit   # Exit on any command failure
set -o nounset   # Exit if using undefined variables
set -o pipefail  # Exit if any command in a pipeline fails

# Check if user provided at least the URL argument
if [ $# -lt 1 ]; then
  echo "Usage: $0 <URL> [expected_codes] [timeout_seconds]"
  exit 2
fi

# Parse command line arguments with default values
URL="$1"                # The URL to check (required)
EXPECTED="${2:-200}"    # Expected HTTP codes (default: 200)
TIMEOUT="${3:-5}"       # Timeout in seconds (default: 5)

# Convert the comma-separated expected codes into an array for easier checking
IFS=',' read -r -a EXPECTED_ARR <<< "$EXPECTED"

# Helper function to generate timestamps for logging
timestamp() { date -u +"%Y-%m-%dT%H:%M:%SZ"; }

# Make the HTTP request and extract only the status code
# If curl fails (network error, timeout, etc.), return "000" as error code
http_code="$(curl -s -S -o /dev/null -w '%{http_code}' --max-time "$TIMEOUT" "$URL" 2>/dev/null || echo "000")"

# Ensure we always have a valid http_code value
[ -n "$http_code" ] || http_code="000"

# Helper function to check if the returned code matches our expected codes
is_expected() {
  local code="$1"
  for e in "${EXPECTED_ARR[@]}"; do
    if [ "$e" = "$code" ]; then
      return 0  # Code found in expected list
    fi
  done
  return 1  # Code not found in expected list
}

# Analyze the results and determine if application is UP or DOWN
if [ "$http_code" = "000" ]; then
  # Network error or timeout occurred
  echo "$(timestamp) DOWN  | $URL | unreachable or timed out (timeout=${TIMEOUT}s)"
  exit 1
fi

if is_expected "$http_code"; then
  # Application is working and returned expected status code
  echo "$(timestamp) UP    | $URL | status=$http_code"
  exit 0
else
  # Application responded but with unexpected status code
  echo "$(timestamp) DOWN  | $URL | unexpected status=$http_code (expected: $EXPECTED)"
  exit 1
fi
