#!/usr/bin/env bash
# Run from the repository root. Produces GW's include/, modules/, out/Release layout.
set -euo pipefail
VERSION=m143
case "$(uname -m)" in
  x86_64) ARCH=x64 ;;
  arm64|aarch64) ARCH=arm64 ;;
  *) echo "Unsupported CPU: $(uname -m)" >&2; exit 1 ;;
esac
case "$(uname -s)" in
  Darwin)
    PLATFORM=macos
    EXTRA_ARGS='skia_use_metal=true'
    EXTRA_CFLAGS='["-mmacosx-version-min=11", "-fno-rtti"]'
    EXTRA_LDFLAGS='["-mmacosx-version-min=11"]'
    ;;
  Linux)
    PLATFORM=linux
    EXTRA_ARGS='skia_use_egl=true skia_use_x11=true'
    EXTRA_CFLAGS='["-fno-rtti"]'
    EXTRA_LDFLAGS='[]'
    ;;
  *) echo "Unsupported OS: $(uname -s)" >&2; exit 1 ;;
esac
# Use the Ninja installed by Homebrew/apt, not depot_tools' Python wrapper.
NINJA=$(command -v ninja) || { echo "Install ninja before building Skia" >&2; exit 1; }
ROOT="$PWD"
OUTPUT="$ROOT/lib/skia"
# Fetch the intended milestone directly instead of syncing today's main first.
if [ ! -d skia ]; then
  git clone --depth 1 --branch "chrome/$VERSION" https://skia.googlesource.com/skia.git
fi
cd skia
# Do not silently package a stale source checkout under the new milestone name.
test "$(git branch --show-current)" = "chrome/$VERSION"
GIT_SYNC_DEPS_SKIP_EMSDK=1 python3 tools/git-sync-deps
bin/gn gen out/Release --fail-on-unused-args --args="is_official_build=true \
  skia_use_gl=true skia_enable_ganesh=true skia_enable_svg=true \
  skia_use_system_icu=false skia_use_system_zlib=false \
  skia_use_system_expat=false skia_use_system_libjpeg_turbo=false \
  skia_use_system_libpng=false skia_use_system_libwebp=false \
  skia_use_system_harfbuzz=false skia_pdf_subset_harfbuzz=true \
  skia_enable_skottie=true target_cpu=\"$ARCH\" \
  extra_cflags=$EXTRA_CFLAGS extra_ldflags=$EXTRA_LDFLAGS \
  cc=\"clang\" cxx=\"clang++\" $EXTRA_ARGS"
"$NINJA" -C out/Release
mkdir -p "$OUTPUT/out/Release"
cp out/Release/*.a "$OUTPUT/out/Release/"
cp -R include modules src "$OUTPUT/"
# Record the precise source and build options alongside the libraries.
git rev-parse HEAD > "$OUTPUT/SKIA_REVISION"
cp out/Release/args.gn "$OUTPUT/SKIA_BUILD_ARGS.gn"
cp LICENSE "$OUTPUT/"
# Headers in modules include other module headers; preserve their directory layout.
find "$OUTPUT/modules" "$OUTPUT/src" -type f ! -name '*.h' ! -name '*.inc' -delete
ASSET="skia-$VERSION-$PLATFORM-Release-$ARCH.tar.gz"
tar -czf "$ROOT/$ASSET" -C "$OUTPUT" .
printf 'Created %s\n' "$ROOT/$ASSET"
