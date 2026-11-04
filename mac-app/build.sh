#!/bin/zsh
set -eu
TASK_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
APP_TARGET="${1:-$HOME/Applications/TLA+ Course.app}"
if [[ "$APP_TARGET" != *.app ]]; then
    print -u2 "Choose an installation path ending in .app."
    exit 1
fi
BUILD_ROOT="$(mktemp -d -t tla-course-build)"
trap 'rm -rf "$BUILD_ROOT"' EXIT
APP_BUNDLE="$BUILD_ROOT/TLA+ Course.app"
mkdir -p "$APP_BUNDLE/Contents/MacOS" "$APP_BUNDLE/Contents/Resources"
MACOSX_DEPLOYMENT_TARGET=14.0 cargo build --release --locked --manifest-path "$TASK_ROOT/mac-app/server/Cargo.toml" --target-dir "$BUILD_ROOT/server-target"
MACOSX_DEPLOYMENT_TARGET=14.0 rustc --edition=2021 -O -C strip=symbols "$TASK_ROOT/mac-app/launcher.rs" -o "$APP_BUNDLE/Contents/MacOS/course-launcher"
swiftc -swift-version 6 -parse-as-library -O -target arm64-apple-macosx14.0 -framework AppKit "$TASK_ROOT/mac-app/MenuBar.swift" "$TASK_ROOT/mac-app/Uninstall.swift" -o "$APP_BUNDLE/Contents/MacOS/TLACourse"
cp "$BUILD_ROOT/server-target/release/tla-course-server" "$APP_BUNDLE/Contents/MacOS/course-server"
cp "$TASK_ROOT/tla-plus-course.html" "$APP_BUNDLE/Contents/Resources/course.html"
swift "$TASK_ROOT/mac-app/Icon.swift" "$BUILD_ROOT/Course.iconset"
swift "$TASK_ROOT/mac-app/UninstallManifest.swift" "$TASK_ROOT" "$APP_BUNDLE/Contents/Resources/uninstall-files.json"
iconutil -c icns "$BUILD_ROOT/Course.iconset" -o "$APP_BUNDLE/Contents/Resources/Course.icns"
cat > "$APP_BUNDLE/Contents/Info.plist" <<'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
<key>CFBundleIdentifier</key><string>local.tla.course</string>
<key>CFBundleName</key><string>TLA+ Course</string>
<key>CFBundleDisplayName</key><string>TLA+ Course</string>
<key>CFBundleExecutable</key><string>TLACourse</string>
<key>CFBundlePackageType</key><string>APPL</string>
<key>CFBundleShortVersionString</key><string>2.1</string>
<key>CFBundleVersion</key><string>4</string>
<key>CFBundleIconFile</key><string>Course</string>
<key>LSMinimumSystemVersion</key><string>14.0</string>
<key>LSApplicationCategoryType</key><string>public.app-category.education</string>
<key>LSUIElement</key><true/>
<key>LSMultipleInstancesProhibited</key><true/>
<key>NSHumanReadableCopyright</key><string>Local TLA+ study course.</string>
</dict></plist>
PLIST
codesign --force --sign - --identifier local.tla.course.server "$APP_BUNDLE/Contents/MacOS/course-server"
codesign --force --sign - --identifier local.tla.course.launcher "$APP_BUNDLE/Contents/MacOS/course-launcher"
codesign --force --sign - --identifier local.tla.course "$APP_BUNDLE"
codesign --verify --deep --strict "$APP_BUNDLE"
if [[ -e "$APP_TARGET" || -L "$APP_TARGET" ]]; then
    EXISTING_ID="$(/usr/libexec/PlistBuddy -c 'Print CFBundleIdentifier' "$APP_TARGET/Contents/Info.plist" 2>/dev/null || true)"
    if [[ "$EXISTING_ID" != local.tla.course ]]; then
        print -u2 "Refusing to replace another app at $APP_TARGET"
        exit 1
    fi
    rm -rf "$APP_TARGET"
fi
mkdir -p "$(dirname "$APP_TARGET")"
ditto "$APP_BUNDLE" "$APP_TARGET"
/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister -f "$APP_TARGET"
mdimport "$APP_TARGET"
print "Installed: $APP_TARGET"
