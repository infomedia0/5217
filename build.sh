#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")"
BUILD="$PWD/build"
DIST="$PWD/dist"
APP="$BUILD/5217.app"
mkdir -p "$BUILD/module-cache" "$DIST" "$APP/Contents/MacOS" "$APP/Contents/Resources"
xcrun swiftc -swift-version 5 -warnings-as-errors -O -target arm64-apple-macosx13.0 -module-cache-path "$BUILD/module-cache" Sources/*.swift -o "$APP/Contents/MacOS/5217"
cp Info.plist "$APP/Contents/Info.plist"
cp Resources/TimerEnd.wav "$APP/Contents/Resources/TimerEnd.wav"
xcrun swift -module-cache-path "$BUILD/module-cache" make-icon.swift "$BUILD/icon.png"
python3 - "$BUILD/icon.png" "$APP/Contents/Resources/AppIcon.icns" <<'PY'
import pathlib, struct, sys
# A full-resolution PNG icon in Apple's documented ICNS container format.
data = pathlib.Path(sys.argv[1]).read_bytes()
body = b'ic10' + struct.pack('>I', len(data) + 8) + data
pathlib.Path(sys.argv[2]).write_bytes(b'icns' + struct.pack('>I', len(body) + 8) + body)
PY
codesign --force --options runtime --timestamp=none --sign - "$APP"
codesign --verify --deep --strict "$APP"
xcrun swiftc -swift-version 5 -module-cache-path "$BUILD/module-cache" Sources/TimerEngine.swift Sources/StopControl.swift Sources/QuoteClassifier.swift Sources/FocusHistory.swift Sources/Quotes.swift Sources/OnlineQuotes.swift Sources/QuoteHTTPClient.swift Sources/LocalStorage.swift Sources/NotificationSounds.swift Tests/main.swift -o "$BUILD/timer-tests"
"$BUILD/timer-tests"
STAGE=$(mktemp -d "$BUILD/stage.XXXXXX")
cp -R "$APP" "$STAGE/5217.app"
ln -s /Applications "$STAGE/Applications"
cp 'Install 5217.txt' "$STAGE/Install 5217.txt"
cp Quotes.md "$STAGE/Quotes.md"
hdiutil makehybrid -hfs -hfs-volume-name '5217 v2.4.7' -o "$STAGE.dmg" "$STAGE"
python3 clean-image-metadata.py "$STAGE.dmg"
hdiutil convert "$STAGE.dmg" -format UDZO -ov -o "$DIST/5217-v2.4.7-Apple-Silicon.dmg"
hdiutil verify "$DIST/5217-v2.4.7-Apple-Silicon.dmg"
printf 'Built: %s\n' "$DIST/5217-v2.4.7-Apple-Silicon.dmg"
