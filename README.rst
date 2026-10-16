Skia binaries for GW
====================

Native builds use Skia chrome/m143 and retain OpenGL (plus Metal on macOS).
The native workflow builds macOS/Linux for x64/arm64 on matching runners.
Run it manually to download Actions artifacts, or push a release tag (v0.2.0
for GW's new default) to build all four archives and attach them to a release.
No release is published by a manual workflow run.

Archives contain include/, modules/, internal headers in src/, out/Release/*.a, the Skia license,
source revision and GN arguments. GW downloads these with ``make prep``.
The minimum macOS version is 11; Linux builds use Ubuntu 22.04.
CPU-wide AVX/AVX512 flags are deliberately avoided; Skia dispatches optimized
implementations at runtime.

Local native build: ``bash build_native.sh`` (clang, ninja, Python 3; on Linux
also install fontconfig, freetype, EGL/GLES and X11 development headers).
Use a fresh checkout or remove the generated skia/ directory to change versions.
The separate experimental WASM workflow remains on m133.
