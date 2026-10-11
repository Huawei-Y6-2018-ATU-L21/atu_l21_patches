#!/bin/bash
# Download LineageOS 17.1 (shallow, about 45 GB). Run inside the build container (/src = tree, /work = this repo).
set -u
# Drop stalled connections (Wi-Fi drop etc.): under 1 KB/s for 5 min -> git fails, repo retries.
export GIT_HTTP_LOW_SPEED_LIMIT=1000 GIT_HTTP_LOW_SPEED_TIME=300
W=${W:-/work}; SRC=${SRC:-/src}
mkdir -p "$SRC"; cd "$SRC"
if [ ! -d .repo ]; then
  repo init -u https://github.com/LineageOS/android.git -b lineage-17.1 --depth=1 --git-lfs -g default,-darwin || exit 1
fi
mkdir -p .repo/local_manifests
cp "$W"/local_manifests/*.xml .repo/local_manifests/
for try in $(seq 1 12); do
  echo "=== sync attempt $try $(date +%T)"
  if repo sync -c -j"${JOBS:-4}" --force-sync --no-clone-bundle --no-tags --optimized-fetch --retry-fetches=3; then
    # The WebView prebuilt is stored in Git LFS
    for a in arm arm64; do git -C external/chromium-webview/prebuilt/$a lfs pull; done
    echo SYNC_OK; exit 0
  fi
  sleep 300
done
echo SYNC_GAVE_UP; exit 1
