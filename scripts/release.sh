#!/bin/bash
# Release Whisker to GitHub
# Usage: ./scripts/release.sh <version>

set -euo pipefail

if [[ $# -lt 1 ]]; then
    echo "Usage: $0 <version>"
    exit 1
fi

VERSION="$1"
TAG="v${VERSION}"
ROOT="$(cd "$(dirname "$0")/.." && pwd)"

cd "$ROOT"

# Build
./scripts/build.sh

# Update version in app bundle
/usr/libexec/PlistBuddy -c "Set :CFBundleShortVersionString $VERSION" "build/Whisker.app/Contents/Info.plist"

# Ad-hoc sign
codesign --force --deep --sign - "build/Whisker.app"

# Zip
cd build
rm -f "Whisker-${VERSION}.zip"
ditto -c -k --keepParent Whisker.app "Whisker-${VERSION}.zip"
cd "$ROOT"

# Release
git tag -f "$TAG"
git push -f origin "$TAG"
gh release create "$TAG" "build/Whisker-${VERSION}.zip" --title "Whisker $VERSION"

echo "Released: https://github.com/vandamd/whisker/releases/tag/$TAG"
