#!/bin/bash

# Check if input file is provided
if [ -z "$1" ]; then
    echo "Usage: ./sip_audit.sh <ip_list.txt>"
    exit 1
fi

IP_FILE=$1
OUTPUT_FILE="sip_audit_results_$(date +%F).txt"

echo "--- SIP Vulnerability Engagement Started: $(date) ---" | tee -a $OUTPUT_FILE

while IFS= read -r line || [ -n "$line" ]; do
    # Clean whitespace
    line=$(echo "$line" | tr -d '\r\n' | xargs)
    [ -z "$line" ] && continue

    # EXTRACTION LOGIC:
    # If the line looks like 50-203-197-133-static..., extract the IP
    if [[ "$line" =~ ^([0-9]{1,3}-[0-9]{1,3}-[0-9]{1,3}-[0-9]{1,3}) ]]; then
        # Replace hyphens with dots
        target_ip=$(echo "${BASH_REMATCH[1]}" | tr '-' '.')
        echo "[*] Extracted IP $target_ip from hostname $line"
    else
        target_ip="$line"
    fi

    echo "[*] Auditing: $target_ip"

    # 1. PRE-CHECK: Fast scan for common SIP ports
    is_sip_active=$(nmap -sV -Pn -p 5060,5061,5070 --host-timeout 5s "$target_ip" | grep -E "open|sip")

    if [ -z "$is_sip_active" ]; then
        echo "    [-] Result: Not a SIP device." | tee -a $OUTPUT_FILE
        echo "-------------------------------------------" >> $OUTPUT_FILE
        continue
    fi

    # 2. ENCRYPTION ANALYSIS
    if echo "$is_sip_active" | grep -q "5060"; then
        echo "    [ALERT] Non-encrypted SIP (5060) - VULNERABLE TO SNOOPING" | tee -a $OUTPUT_FILE
    fi

    if echo "$is_sip_active" | grep -q "5061"; then
        echo "    [INFO] Encrypted SIPS (5061) detected." | tee -a $OUTPUT_FILE
    fi

    # 3. SIPVICIOUS FINGERPRINTING
    echo "    - Gathering SIP Fingerprint..."
    svmap "$target_ip" -p 5060,5061 --quiet | tee -a $OUTPUT_FILE

    # 4. EXTENSION SNOOPING
    echo "    - Checking for extension visibility..."
    svwar "$target_ip" -e 100-105 --quiet | tee -a $OUTPUT_FILE

    echo "-------------------------------------------" >> $OUTPUT_FILE
done < "$IP_FILE"

echo "[+] Audit Complete. Results saved to $OUTPUT_FILE"