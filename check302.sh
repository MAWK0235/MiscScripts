#!/bin/bash

# TARS-TACTICAL-V3: Non-Redirect Divergence Script
# Purpose: Identify HTTP targets that DO NOT redirect to HTTPS.

INPUT="targets.txt"
OUTPUT="non_redirecting_targets.txt"

# Initialize output file
> "$OUTPUT"

if [[ ! -f "$INPUT" ]]; then
    echo "DATA NOT FOUND: $INPUT"
    exit 1
fi

echo "[*] Scanning for non-redirecting HTTP targets..."

while IFS= read -r line || [[ -n "$line" ]]; do
    # 1. Clean line: remove commas, spaces, and carriage returns
    target=$(echo "$line" | tr -d ',\r' | xargs)

    # 2. Skip empty lines
    [[ -z "$target" ]] && continue

    # 3. Skip if already HTTPS (not relevant for HTTP->HTTPS check)
    if [[ "$target" == https://* ]]; then
        continue
    fi

    # 4. Standardize to HTTP
    if [[ "$target" != http://* ]]; then
        url="http://$target"
    else
        url="$target"
    fi

    # 5. Execute header check
    # -I: Fetch headers only
    # -s: Silent mode
    # -o /dev/null: Discard body
    # -w "%{http_code}": Extract code
    # --max-time 5: Avoid hanging on dead hosts
    status=$(curl -I -s -o /dev/null -w "%{http_code}" --max-time 5 "$url")

    # 6. Filter: If status is NOT 302, it is a target of interest
    if [[ "$status" != "302" ]]; then
        # Log to console and file
        echo "[-] NO REDIRECT (Status: $status): $url"
        echo "$url" >> "$OUTPUT"
    fi

done < "$INPUT"

echo "[+] Scan complete. Results saved to $OUTPUT"
