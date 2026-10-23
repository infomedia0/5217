#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."
mkdir -p build/module-cache
xcrun swiftc -swift-version 5 -module-cache-path "$PWD/build/module-cache" Sources/TimerEngine.swift Sources/StopControl.swift Sources/QuoteClassifier.swift Sources/FocusHistory.swift Sources/Quotes.swift Sources/OnlineQuotes.swift Sources/QuoteHTTPClient.swift Sources/LocalStorage.swift Sources/NotificationSounds.swift Tests/main.swift -o build/timer-tests
build/timer-tests
