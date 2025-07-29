#!/bin/bash

# --- Configuration ---
TARGET_URL="http://localhost:8091"
CHECK_INTERVAL=5    # Seconds between checks
MAX_ATTEMPTS=60     # Maximum number of attempts before giving up (e.g., 60 * 5s = 5 minutes timeout)
ATTEMPT_COUNT=0

echo "Commencing availability check for ${TARGET_URL}..."
echo "Will check every ${CHECK_INTERVAL} seconds for up to ${MAX_ATTEMPTS} attempts."

# --- Loop to continuously check ---
while [ $ATTEMPT_COUNT -lt $MAX_ATTEMPTS ]; do
    ATTEMPT_COUNT=$((ATTEMPT_COUNT + 1))
    echo "Attempt ${ATTEMPT_COUNT}/${MAX_ATTEMPTS}: Checking ${TARGET_URL}..."

    # Use curl with specific options for a non-verbose, timeout-aware check
    # -s: Silent mode (don't show progress meter or error messages)
    # -o /dev/null: Discard output (don't save the response body)
    # -w "%{http_code}" : Print only the HTTP status code
    # --connect-timeout 5: Timeout for the connection phase
    HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" --connect-timeout 5 "${TARGET_URL}")

    # Check if curl command itself succeeded and if the HTTP status code is a success (2xx or 3xx)
    if [ $? -eq 0 ] && [[ "$HTTP_CODE" =~ ^[23] ]]; then
        echo "SUCCESS: ${TARGET_URL} is AVAILABLE! HTTP Status: ${HTTP_CODE}"
        exit 0 # Exit with success
    elif [ $? -ne 0 ]; then
        echo "WARNING: Could not connect to ${TARGET_URL}. Curl error."
    else
        echo "WARNING: ${TARGET_URL} returned HTTP Status: ${HTTP_CODE}. Not yet considered available."
    fi

    # Wait before the next attempt
    sleep ${CHECK_INTERVAL}
done

# --- If loop finishes without success ---
echo "ERROR: Timed out after ${MAX_ATTEMPTS} attempts. ${TARGET_URL} is NOT AVAILABLE."
exit 1 # Exit with failure
