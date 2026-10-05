#!/usr/bin/env bash
# Builds Coucou for your own Mac, optimized and signed ad hoc: no Apple
# Developer account, no provisioning profile, nothing leaves the machine.
#
#   ./scripts/local-build.sh            without the iPhone link (default)
#   ./scripts/local-build.sh --iphone   with the iPhone link (PHONE_LINK)
#
# The iPhone link needs iCloud and push entitlements that only the
# maintainer's Developer ID profile grants, so an ad hoc --iphone build
# compiles the code but iCloud will not work. It is for checking the code
# builds; the notarized release is made by scripts/release.sh.
#
# The app lands in /tmp/coucou-local/Coucou.app. Keep the bundle identifier
# (fr.louisraille.NotchBuddy): Keychain items, preferences and permissions
# depend on it.
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
BUILD_DIR="/tmp/coucou-local"
CONFIG="Release"

case "${1:-}" in
  "") ;;
  --iphone) CONFIG="ReleaseCloud" ;;
  *) echo "error: unknown option '$1' (the only option is --iphone)" >&2; exit 1 ;;
esac

cd "$REPO_ROOT/NotchBuddy"
xcodegen generate
rm -rf "$BUILD_DIR" && mkdir -p "$BUILD_DIR"

# Ad hoc signature ("-"): drops the maintainer's team, identity, timestamp and profile.
xcodebuild \
  -project NotchBuddy.xcodeproj \
  -scheme NotchBuddy \
  -configuration "$CONFIG" \
  build \
  CODE_SIGN_IDENTITY="-" \
  CODE_SIGNING_REQUIRED=YES \
  CODE_SIGNING_ALLOWED=YES \
  DEVELOPMENT_TEAM="" \
  PROVISIONING_PROFILE_SPECIFIER="" \
  OTHER_CODE_SIGN_FLAGS="" \
  CONFIGURATION_BUILD_DIR="$BUILD_DIR" \
  -quiet

codesign --verify --deep --strict "$BUILD_DIR/Coucou.app"
echo "✓ Built $BUILD_DIR/Coucou.app ($CONFIG, ad hoc signature)."
echo "  Move it to /Applications, then open it (right-click → Open the first time)."
