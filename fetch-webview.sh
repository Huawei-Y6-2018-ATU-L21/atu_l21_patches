#!/bin/bash
# Download LineageOS Chromium WebView 154.0.8037.57 (arm64, BSD licensed) from the LineageOS
# Git LFS server and verify it. Usage: ./fetch-webview.sh <output webview.apk>
set -euo pipefail
OUT=${1:?usage: fetch-webview.sh <output apk>}
OID=3b98460ccd41b2a1851c5a46e6dec6f86f1d14302ff2fa4deeb1d781e32f89a4
SIZE=267260603
LFS=https://review.lineageos.org/LineageOS/android_external_chromium-webview_prebuilt_arm64.git/info/lfs/objects/batch
URL=$(curl -fsS -X POST -H "Accept: application/vnd.git-lfs+json" -H "Content-Type: application/vnd.git-lfs+json" \
  -d "{\"operation\":\"download\",\"transfers\":[\"basic\"],\"objects\":[{\"oid\":\"$OID\",\"size\":$SIZE}]}" "$LFS" \
  | python3 -c "import json,sys; print(json.load(sys.stdin)['objects'][0]['actions']['download']['href'])")
curl -fL -o "$OUT" "$URL"
echo "$OID  $OUT" | sha256sum -c -
