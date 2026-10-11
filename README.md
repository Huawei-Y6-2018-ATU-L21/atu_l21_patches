# atu_l21_patches — branch `lineage-17.1`

Source patches and build scripts for the **unofficial LineageOS 17.1 (Android 10)** build for the Huawei Y6 2018
(ATU-L21). Not affiliated with or endorsed by the LineageOS project. The Android 12 (phh v416) patches are on `main`.

## How the build is put together

LineageOS 17.1 + phh's treble layer for A-only devices with an Android 8.0 vendor, applied the way
[AndyYan's lineage_build_unified](https://github.com/AndyCGYan/lineage_build_unified) does it (pinned commits), plus:

| Patch | Project | Why |
|---|---|---|
| `patches/atu/frameworks_native.patch` | frameworks/native | `Parcel` packed to the Android 8.0 size (104/52 bytes): 8.0 vendor binaries allocate it on the stack — RIL, camera and display tools overwrite memory otherwise. Also `gpuservice` runs as UID 1072 (the 8.0 init does not know the `gpu_service` user name). |
| `patches/atu/build_make.patch` | build/make | The Huawei-modified 8.0 init on this phone **never reads `/system/build.prop`** (only `/system/etc/prop.default`, then the vendor). `TARGET_DEFAULT_PROP_INCLUDES_BUILD_PROP` appends build.prop to prop.default and derives `ro.build.fingerprint`. |
| `patches/atu/device_phh_treble.patch` | device/phh/treble | `TARGET_PHH_NO_HARDWARE_OVERLAYS`: no "Phh Treble Settings" app and no overlays for other phones; the device picks the 6 overlays that are active on ATU-L21. |
| `patches/phh-adapted/platform_system_bt/0001-…` | system/bt | phh's `BTM_BYPASS_EXTRA_ACL_SETUP` patch adapted to the 2026 tree; the BLE re-encryption security fix stays outside the bypass. |

Not applied: AndyYan's microG signature spoofing patch — lineage-17.1 has its own `isMicrogSigned()`.
`build.sh` sets `SKIP_ABI_CHECKS=true`: the Parcel change is an intended VNDK ABI change.

Device configuration: [android_device_huawei_atu_l21 `lineage-17.1`](https://github.com/Huawei-Y6-2018-ATU-L21/android_device_huawei_atu_l21/tree/lineage-17.1),
packages: [android_vendor_atu `lineage-17.1`](https://github.com/Huawei-Y6-2018-ATU-L21/android_vendor_atu/tree/lineage-17.1).

## Building

The builder image is the one from the main repository (`build/docker/Dockerfile`, Ubuntu 20.04). About 45 GB of
source, 60 GB of `out/`, 16 GB RAM + swap recommended.

```bash
git clone -b lineage-17.1 https://github.com/Huawei-Y6-2018-ATU-L21/atu_l21_patches work
mkdir -p src ccache
run() { docker run --rm -i -v $PWD/src:/src -v $PWD/work:/work -v $PWD/ccache:/ccache \
        -v $HOME/.gitconfig:/home/builder/.gitconfig:ro -e JOBS -e LUNCH atu-l21-builder bash -c "$*"; }
run /work/scripts/sync.sh          # repo sync (shallow) + WebView LFS objects
run /work/scripts/prepare.sh       # AndyYan/phh steps + ATU-L21 patches (each one a git commit)
(cd src/vendor/atu && ./fetch-prebuilts.sh)   # F-Droid / microG APKs from their official sources
LUNCH=atu_l21-userdebug run /work/scripts/build.sh systemimage
```

`manifest/pinned-manifest.xml` records the exact upstream revisions of the published build.

## Ramdisk

The ROM keeps the **stock Android 8.0 ramdisk**, with file-based encryption disabled (Android 10's vold cannot set
up FBE with the 8.0 init). The stock ramdisk contains Huawei's init and is not redistributed;
`scripts/make-ramdisk-nofbe.sh` builds it from your own `UPDATE.APP` (8.0.0.133 C432 gives sha256 `49f7346a…`).

## GApps

Not included (Google's apps may not be redistributed). MindTheGapps 10.0.0 arm64 works after
`scripts/patch_gapps_aonly.py` — see the main repository's docs/LINEAGE-17.1.md.
