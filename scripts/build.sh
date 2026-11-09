#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."
build_target="${1:-native}"
case "$build_target" in
  native) architectures=("$(uname -m)"); output_directory="$PWD/build" ;;
  universal) architectures=(arm64 x86_64); output_directory="$PWD/build/universal" ;;
  *) printf 'Usage: %s [native|universal]\n' "$0" >&2; exit 2 ;;
esac
mkdir -p .build/clang-cache .build/swift-cache build
export CLANG_MODULE_CACHE_PATH="$PWD/.build/clang-cache"
export SWIFTPM_MODULECACHE_OVERRIDE="$PWD/.build/swift-cache"
build_flags=(-c release --product MacDraw --disable-sandbox --cache-path "$PWD/.build/package-cache")
binaries=()
for architecture in "${architectures[@]}"; do
  swift build "${build_flags[@]}" --triple "$architecture-apple-macosx14.0"
  binary_directory="$(swift build "${build_flags[@]}" --triple "$architecture-apple-macosx14.0" --show-bin-path)"
  binaries+=("$binary_directory/MacDraw")
done

staging_directory="$(mktemp -d "$PWD/.build/app-package.XXXXXX")"
trap 'rm -rf "$staging_directory"' EXIT
packaged_app="$staging_directory/Mac Draw.app"
mkdir -p "$packaged_app/Contents/MacOS" "$packaged_app/Contents/Resources"
if [[ ${#binaries[@]} -eq 1 ]]; then
  cp "${binaries[0]}" "$packaged_app/Contents/MacOS/MacDraw"
else
  xcrun lipo -create "${binaries[@]}" -output "$packaged_app/Contents/MacOS/MacDraw"
fi
chmod 755 "$packaged_app/Contents/MacOS/MacDraw"
cp Resources/Info.plist "$packaged_app/Contents/Info.plist"
cp LICENSE "$packaged_app/Contents/Resources/LICENSE.txt"
swift scripts/make-icon.swift "$PWD/build/AppIcon.iconset" "$packaged_app/Contents/Resources/AppIcon.icns"
codesign --force --sign - --timestamp=none "$packaged_app"
codesign --verify --deep --strict "$packaged_app"
plutil -lint "$packaged_app/Contents/Info.plist"
xcrun lipo "$packaged_app/Contents/MacOS/MacDraw" -verify_arch "${architectures[@]}"

mkdir -p "$output_directory"
rm -rf "$output_directory/Mac Draw.app"
mv "$packaged_app" "$output_directory/Mac Draw.app"
printf '\nReady: %s\n' "$output_directory/Mac Draw.app"
xcrun lipo -info "$output_directory/Mac Draw.app/Contents/MacOS/MacDraw"
