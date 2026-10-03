#!/bin/bash
# Apply the ATU-L21 patches to a phh v416 (android-12.1.0_r11) source tree.
# Usage: ./apply.sh /path/to/android/tree
set -euo pipefail
TREE=$(realpath "${1:?usage: apply.sh <android tree>}")
HERE=$(cd "$(dirname "$0")" && pwd)

declare -A PROJ=(
  [bionic]=bionic
  [device_phh_treble]=device/phh/treble
  [external_chromium-webview]=external/chromium-webview
  [external_tinyxml2]=external/tinyxml2
  [frameworks_av]=frameworks/av
  [frameworks_base]=frameworks/base
  [frameworks_native]=frameworks/native
  [frameworks_opt_net_wifi]=frameworks/opt/net/wifi
  [hardware_interfaces]=hardware/interfaces
  [system_core]=system/core
  [system_libbase]=system/libbase
  [system_libhidl]=system/libhidl
  [system_linkerconfig]=system/linkerconfig
  [system_logging]=system/logging
  [system_sepolicy]=system/sepolicy
)

# Jelly (LineageOS browser, lineage-19.1) is not part of the phh manifest.
JELLY_COMMIT=d4a816b2358996e505ca1d6cee2fbacf9166fce7
if [ ! -d "$TREE/packages/apps/Jelly" ]; then
  git clone -b lineage-19.1 https://github.com/LineageOS/android_packages_apps_Jelly "$TREE/packages/apps/Jelly"
  git -C "$TREE/packages/apps/Jelly" checkout -q "$JELLY_COMMIT"
fi
PROJ[packages_apps_Jelly]=packages/apps/Jelly

for name in "${!PROJ[@]}"; do
  dir="$TREE/${PROJ[$name]}"
  echo "==> ${PROJ[$name]}"
  git -C "$dir" apply --whitespace=nowarn "$HERE/patches/$name.patch"
done

# Updated Chromium WebView APK (binary, not stored in this repo).
"$HERE/fetch-webview.sh" "$TREE/external/chromium-webview/prebuilt/arm64/webview.apk"
echo "All patches applied."
