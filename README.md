# ATU-L21 Android 12 source patches

Patches that make Android 12 (phh-treble **v416**, AOSP `android-12.1.0_r11`) run on the
**Huawei Y6 2018 (ATU-L21)** with its stock **Android 8.0 (Oreo) vendor** and a **3.18 kernel**.

> Why each patch exists, how it was found and how it was verified is documented in the main guide:
> [`android_huawei_atu_l21` → docs/PATCHES.md](https://github.com/Huawei-Y6-2018-ATU-L21/android_huawei_atu_l21/blob/main/docs/PATCHES.md).

## Contents

| Path | Purpose |
|---|---|
| `manifest/phh-v416-slim.xml` | Repo manifest used for the build (phh v416 minus unused device/* projects) |
| `manifest/phh-v416-full.xml` | Original phh v416 manifest |
| `manifest/pinned-revisions.txt` | Exact commit of each of the 1017 projects (`<path> <sha>`) |
| `patches/<project>.patch` | One `git diff` per modified project (new files included) |
| `apply.sh` | Applies every patch to a synced tree, clones Jelly and fetches the WebView |
| `fetch-webview.sh` | Downloads and verifies LineageOS Chromium WebView 154.0.8037.57 (arm64) |

## Usage

```bash
mkdir -p ~/atu-a12 && cd ~/atu-a12
repo init -u https://github.com/phhusson/treble_manifest -b android-12.0   # or copy manifest/phh-v416-slim.xml
cp /path/to/atu_l21_patches/manifest/phh-v416-slim.xml .repo/manifests/
repo init -m phh-v416-slim.xml
repo sync -c -j4 --no-tags --no-clone-bundle
# optional: pin every project to the exact revision that was built
while read -r path sha; do git -C "$path" checkout -q "$sha"; done < /path/to/atu_l21_patches/manifest/pinned-revisions.txt
/path/to/atu_l21_patches/apply.sh "$PWD"
```

Then add the device and vendor repositories and build — see the main guide's `docs/BUILDING.md`.

## Patched projects

| Project | What |
|---|---|
| `frameworks/native` | **Parcel shrunk to the Android 8.0 size (104/52 bytes)** — fixes stack corruption in 8.0 vendor binaries (modem/RIL, camera, display tools); RenderEngine Adreno binning hint (SurfaceFlinger GPU composition 77 → 2.4 ms); system-side `vndservicemanager` |
| `frameworks/av` | Never block on the dead 8.0 OMX service; tolerate the 8.0 codec XML; system-side OMX service (hardware video decoding) |
| `frameworks/base` | microG signature spoofing also covers `signingInfo`; VINTF kernel mismatch only logged |
| `system/core` | init/ueventd/fs_mgr fixes for an 8.0 vendor, cgroup v1 fallback, `/odm/etc/firmware` (speaker amplifier → audio), debug helpers |
| `system/linkerconfig` | VNDK-less legacy vendor support, `legacy_vendor` section, APEX sphal → `/system/${LIB}` (video) |
| `bionic` | linker: a `dir.` entry may be an exact binary path |
| `hardware/interfaces` | Old `android::HidlUtils` with 8.0 struct layouts for the audio HAL |
| `system/libbase`, `external/tinyxml2`, `system/libhidl`, `system/logging` | Old symbols that 8.0 vendor binaries import |
| `system/sepolicy` | Drop the tetheroffload hwservice labels that conflict with the 8.0 vendor |
| `frameworks/opt/net/wifi` | `libwifi-system` → `libwifi-system-iface` dependency |
| `device/phh/treble` | `ro.logd.auditd=false`, Bluetooth default name |
| `external/chromium-webview` | Chromium WebView 154 (`optional_uses_libs`) |
| `packages/apps/Jelly` | Jelly replaces Browser2 |

All changes carry an `ATU-L21` comment in the source.

## License

Patches to AOSP code are provided under the Apache License 2.0 (see `LICENSE`), matching the files they modify.
