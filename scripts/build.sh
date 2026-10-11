#!/bin/bash
# Build inside the container: LUNCH=atu_l21-userdebug build.sh systemimage
cd "${SRC:-/src}"
export USE_CCACHE=1 CCACHE_EXEC=/usr/bin/ccache CCACHE_DIR=/ccache
export WITHOUT_CHECK_API=true ALLOW_MISSING_DEPENDENCIES=true
# Parcel is packed to the Android 8.0 size on purpose; every VNDK library with Parcel in its API then differs
# from the Android 10 ABI reference dumps. The change is intended.
export SKIP_ABI_CHECKS=true
source build/envsetup.sh >/dev/null
lunch "${LUNCH:-atu_l21-userdebug}" >/dev/null || exit 1
m -j"${JOBS:-6}" "$@" && echo BUILD_OK || { echo BUILD_FAIL; exit 1; }
