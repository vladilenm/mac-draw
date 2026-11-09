#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."
mkdir -p .build/clang-cache .build/swift-cache
export CLANG_MODULE_CACHE_PATH="$PWD/.build/clang-cache"
export SWIFTPM_MODULECACHE_OVERRIDE="$PWD/.build/swift-cache"
swift run --disable-sandbox --cache-path "$PWD/.build/package-cache" DrawingCoreChecks
swift build --product MacDraw --disable-sandbox --cache-path "$PWD/.build/package-cache"
.build/debug/MacDraw --check-rendering
.build/debug/MacDraw --check-windows
