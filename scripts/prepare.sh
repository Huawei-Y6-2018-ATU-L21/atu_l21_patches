#!/bin/bash
# Apply all patches to a freshly synced tree: AndyYan's lineage_build_unified (buildbot_treble.sh, lineage-17.1)
# steps + phh patches + ATU-L21 patches. Run once, inside the build container (/src = tree, /work = this repo).
# Every step is a git commit in the respective project.
set -eu
W=${W:-/work}; cd "${SRC:-/src}"
H=$W/helpers
clone() {  # url sha dir
  [ -d "$H/$3" ] || { git clone -q "$1" "$H/$3"; git -C "$H/$3" checkout -q "$2"; }
}
clone https://github.com/AndyCGYan/lineage_build_unified   06f242ffe4563a57af4d9ca4f82dbed6127f5256 lineage_build_unified
clone https://github.com/AndyCGYan/lineage_patches_unified 79b5b414a751c82b32c67e691bf542f4844216be lineage_patches_unified
clone https://github.com/AndyCGYan/treble_experimentations 4a1742e0075a3592e44b63e5ba3b4456cb2c0f43 treble_experimentations
BL=$H/lineage_build_unified

# "git revert <sha>" needs the history the shallow clone does not have
unshallow() { git -C "$1" fetch -q --unshallow "$(git -C "$1" remote | head -1)" 2>/dev/null || true; }
for p in device/phh/treble vendor/lineage frameworks/native system/hardware/interfaces system/sepolicy; do unshallow $p; done
am() { git -C "$1" am -q "$BL/patches/$2"; }

echo "### Revert the LineageOS FOD implementation"
am frameworks/base 0001-Squashed-revert-of-LOS-FOD-implementation.patch
am frameworks/native 0001-Revert-surfaceflinger-Add-support-for-extension-lib.patch
git -C vendor/lineage revert --no-edit 612c5a846ea5aed339fe1275c119ee111faae78c

echo "### phh patches"
rm -f device/*/sepolicy/common/private/genfs_contexts
(cd device/phh/treble && git clean -fdx && bash generate.sh lineage)
# One phh patch (system/bt) no longer applies to the 2026 tree: use the adapted copy.
PP=$(mktemp -d); cp -r "$H/lineage_patches_unified/patches/." "$PP/"
cp "$W"/patches/phh-adapted/platform_system_bt/*.patch "$PP/platform_system_bt/"
bash "$H/treble_experimentations/apply-patches.sh" "$PP"
rm -rf "$PP"

echo "### Generic patches"
am frameworks/base 0001-UI-Revive-navbar-layout-tuning-via-sysui_nav_bar-tun.patch
am frameworks/base 0001-Disable-vendor-mismatch-warning.patch
# Not applied: 0001-Allow-selective-signature-spoofing-for-microG.patch — lineage-17.1 now has its own
# isMicrogSigned() (official microG signature, debuggable builds, signatures and signingInfo).
am lineage-sdk 0001-sdk-Invert-per-app-stretch-to-fullscreen.patch
am packages/apps/LineageParts 0001-LineageParts-Invert-per-app-stretch-to-fullscreen.patch
am vendor/lineage 0001-vendor_lineage-Log-privapp-permissions-whitelist-vio.patch

echo "### GSI patches"
am build/make 0001-build-Don-t-handle-apns-conf.patch
git -C device/phh/treble revert --no-edit 82b15278bad816632dcaeaed623b569978e9840d
for f in 0001-Remove-fsck-SELinux-labels.patch 0001-treble-Add-overlay-lineage.patch \
         0001-treble-Don-t-specify-config_wallpaperCropperPackage.patch 0001-treble-Don-t-handle-apns-conf.patch \
         0001-TEMP-treble-Fix-init.treble-environ.rc-hardcode-for-.patch; do am device/phh/treble $f; done
git -C frameworks/native revert --no-edit 581c22f979af05e48ad4843cdfa9605186d286da
am hardware/lineage/interfaces 0001-cryptfshw-Remove-dependency-on-generated-kernel-head.patch
git -C system/hardware/interfaces revert --no-edit 5c145c49cc83bfe37c740bcfd3f82715ee051122
git -C system/sepolicy revert --no-edit d12551bf1a6e8a9ece6bbb98344a27bde7f9b3e1
am system/sepolicy 0001-Revert-sepolicy-Address-denials-for-legacy-last_kmsg.patch
am vendor/lineage 0001-build_soong-Disable-generated_kernel_headers.patch

echo "### ATU-L21 patches"
P=$W/patches/atu
# Parcel packed to the Android 8.0 size (RIL / camera / display tools) + gpuservice numeric UID for the 8.0 init
git -C frameworks/native apply --index "$P/frameworks_native.patch"
git -C frameworks/native commit -q -m "ATU-L21: Parcel 8.0 size, gpuservice numeric UID"
# The Huawei 8.0 init never reads /system/build.prop: optional append to prop.default
git -C build/make am -q "$P/build_make.patch"
# Optional phh hardware_overlay list -> no "Phh Treble Settings" app, only the overlays ATU-L21 uses
git -C device/phh/treble am -q "$P/device_phh_treble.patch"

echo PREPARE_OK
