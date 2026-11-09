#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."

version="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' Resources/Info.plist)"
if [[ ! "$version" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
  printf 'Expected a numeric version such as 1.0.0, got: %s\n' "$version" >&2
  exit 1
fi
./scripts/build.sh universal

staging_directory="$(mktemp -d "$PWD/.build/release-package.XXXXXX")"
trap 'rm -rf "$staging_directory"' EXIT
release_directory="$staging_directory/MacDraw-$version"
mkdir -p "$release_directory" dist
ditto --norsrc --noextattr --noacl 'build/universal/Mac Draw.app' "$release_directory/Mac Draw.app"
cp Resources/INSTALL.txt "$release_directory/INSTALL.txt"
cp LICENSE "$release_directory/LICENSE.txt"
archive="MacDraw-universal.zip"
rm -f "dist/$archive"
ditto -c -k --norsrc --noextattr --noacl --keepParent "$release_directory" "dist/$archive"
cp Resources/INSTALL.txt dist/INSTALL.txt
(
  cd dist
  shasum -a 256 "$archive" INSTALL.txt > SHA256SUMS.txt
)
printf '\nRelease files:\n'
ls -lh "dist/$archive" dist/INSTALL.txt dist/SHA256SUMS.txt
