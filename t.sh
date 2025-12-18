#!/usr/bin/env bash
set -euo pipefail

BASE="https://developer.android.com"

echo "Fetching Pixel Beta metadata..."

# 1. Fetch version list
versions_html=$(curl -s "$BASE/about/versions")

# 2. Find latest Android version / QPR page
latest_page=$(echo "$versions_html" | grep -oP 'https://developer.android.com/about/versions/.*?[0-9]"' | sort -r | head -n1 | tr -d '"')

latest_html=$(curl -s "$latest_page")

# 3. Find OTA QPR Beta page
ota_rel=$(echo "$latest_html" | grep -oP 'href=".*download-ota.*qpr.*?"' | head -n1 | cut -d'"' -f2)
ota_page="$BASE$ota_rel"

ota_html=$(curl -s "$ota_page")

# 4. Extract rows
model_list=($(echo "$ota_html" | grep -oP '(?<=<td>).*?(?=</td>)'))
product_list=($(echo "$ota_html" | grep -oP 'ota/.*?_beta' | uniq))
ota_url_list=($(echo "$ota_html" | grep -oP 'https.*?ota/.*?_beta.*?' | uniq))

# 5. Random selection
idx=$(shuf -i 0-$((${#product_list[@]}-1)) -n1)

MODEL="${model_list[$idx]}"
PRODUCT="${product_list[$idx]}"
DEVICE="${PRODUCT/_beta/}"
OTA_URL="${ota_url_list[$idx]}"

echo "Selected: $MODEL ($PRODUCT)"
echo "OTA URL = $OTA_URL"

# 6. Fetch partial ZIP (first 4KB)
partial_data=$(curl -s --range 0-4095 "$OTA_URL" | strings)

# 7. Extract metadata
FINGERPRINT=$(echo "$partial_data" | grep -oP 'post-build=.*' | head -n1 | cut -d'=' -f2)
SECURITY_PATCH=$(echo "$partial_data" | grep -oP 'security-patch-level=.*' | head -n1 | cut -d'=' -f2)

if [[ -z "$FINGERPRINT" || -z "$SECURITY_PATCH" ]]; then
    echo "ERROR: Could not extract fingerprint or patch!"
    exit 1
fi

echo "Fingerprint extracted: $FINGERPRI
