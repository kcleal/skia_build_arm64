#!/usr/bin/env bash
# Compatibility entry point; the shared builder supports Linux and macOS.
set -euo pipefail
cd "$(dirname "$0")"
exec bash build_native.sh
