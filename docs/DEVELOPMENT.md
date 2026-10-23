# 5217 v2.4.7

A native SwiftUI/AppKit timer for Apple silicon, macOS 13 and later.

## New in v2.4.7

- Cleaner Settings header with one heading and a shared return-to-timer button.
- Equal-width Sounds, Releases and About tabs replace the crowded navigation row.
- Current version/build details are in About; the current release marker remains in Releases.
- About ends with “Built by Arjun Sabharwal.”

## Included from v2.4.6

- Use the upward chevron in the quote card to hide quotes.
- The collapsed Quotes bar offers Show quotes and the timer window becomes shorter.
- Quotes open expanded on every launch. The choice is kept only during the current run.
- Countdown and quote rotation continue while hidden. Settings, History and Stop
  confirmation still open at full size inside the same window.

## Included from v2.4.5

- Notification duration in Settings > Sounds: 1, 5, 10 or 15 seconds (default 5).
- The chosen limit applies to timer-end audio, Test sound and selection previews.
  Shorter tones finish naturally; changing duration stops current playback.
- The duration is stored with the selected tone in sound-settings.json; old
  preferences preserve their tone and default to 5 seconds. Stop still silences immediately.
- About includes a fuller explanation of the 52/17 approach and five reading links.
- Footer clearly explains quitting through the menu bar or Dock.
- 164 automated checks and three native playback checks passed.

## Included from v2.4.4

- More conservative theme filtering for motivational Focus quotes and calming Break quotes.
- Mixed-theme and unclear quotes are skipped. Rules are deterministic text matching,
  not AI or guaranteed semantic understanding.
- Separate Focus/Break JSON collections retain prior suitable quotes when a new batch
  lacks one mode, up to 25 online quotes per mode. Curated fallbacks remain available.
- Existing caches are reclassified and punctuation/case duplicates removed.
- Same ZenQuotes endpoint, request limits, network security and offline behavior.
- Footer moved down by 8 pixels; no quote-related layout or controls changed.
- 164 checks passed. See Change-Notes.md for implementation details.

## Included from v2.4.3

Settings > About briefly explains the 52/17 approach and links to
[Optima Results Coaching’s article](https://optimaresultscoaching.com/the-5217-rule-for-productivity/).

Stop after Skip silences app audio and dismisses delivered 5217 banners on its
first click. A second click opens an in-window confirmation. Keep timer / Escape
cancels; Yes, stop timer returns to paused Focus 52:00 and preserves completed
history. Unfinished timers are not recorded. Timer changes reset the two-click sequence.

Timer-end audio is now owned by the app (NSSound), so Stop can interrupt long tones.
Scheduled macOS banners are silent and no longer own the timer audio. 5217's Sound
on/off control and Mac output volume control this playback. macOS notification
sound settings do not control this app-owned playback. No sound is played for old
catch-up events; a manually sleeping/off Mac cannot be guaranteed to sound on time.
A system-owned sound started by an older app build cannot be stopped retroactively.

## Included from v2.4.2

Removed the header status dot and status messages. The logo and Settings icon
remain in the header.

## Included from v2.4.1

Settings and Focus history now replace the timer content inside the existing
main window. Back or Escape returns to the timer; the countdown keeps running.
History is positioned below Sound on/off at the bottom right.
Both pages fit the timer window size. No Settings/History sheet or extra window
is created. Command-comma also opens the integrated Settings page.

## Included from v2.4

- History button beside today's focus-session total opens a separate modal.
- All completed focus sessions appear newest first, with completion time and 52m duration.
- Calendar-week chart uses local Monday–Sunday weeks and daily/weekly hours and minutes.
- Browse previous weeks or return to This week. Empty days remain visible.
- History uses owner-only, atomic monthly JSON files under
  `~/Library/Application Support/5217/FocusHistory/YYYY-MM.json` (UTC month names).
- Available completions in the old timer file migrate automatically, without duplicates.
  Earlier app versions retained only 31 days; already discarded records cannot be recovered.
  New archived records have no age-based deletion. Each JSON file is read with a 1 MiB limit.
- Breaks, reset/skipped timers, and unfinished focus sessions are excluded.
  Each complete focus timer counts as 52 minutes, attributed to its local completion day;
  time spent paused is excluded by timer behavior. Existing manual-sleep catch-up semantics remain.
- Malformed history files are preserved and an error appears in the modal; no database is used.

## Included from v2.3.4

Removed Test sound from the main screen; use Settings > Sounds > Test sound.
The main-screen Sound on/off control remains available.

## Included from v2.3.3

Fixed first-open Settings layout by sharing one content area between sections
and removing the sound pane’s nested fixed size.

## Included from v2.3.2

Settings now includes Sounds and Version history tabs, with the installed version
and build number read from the application bundle. Release notes cover v1–v2.3.2.
Security-Audit.md and Metrics.json describe the preceding v2.3.1 audit.

## Included from v2.3.1

Security and maintenance release: bounded network downloads, redirect rejection,
validated cached quotes and timer state, owner-only atomic JSON writes, safer
sound-cache handling, and hardened runtime. Sound playback and selection now
live in SoundController; LocalStorage and QuoteHTTPClient isolate input boundaries.
See Security-Audit.md and Metrics.json for scope, findings, tests, and measurements.

## Included from v2.3

- Gear icon, app-menu Settings, menu-bar Settings, and Command-comma shortcut.
- Searchable notification-sound chooser with selection, individual previews, and Stop preview.
- Discovers installed Mac alert sounds and optional modern/classic Apple alert tones and ringtones.
- Saves the selected sound and uses it for Focus completion, Break completion, and Test sound.
- Changes update an already-running timer’s pending notification without changing its deadline.
- Selection defaults to the bundled 5217 chime when upgrading; missing tones fall back safely.

## Included from v2.2

- ZenQuotes batch API integration without an API key.
- Online quotes are sorted into Focus or Rest using local keyword matching.
- Online quote batches are saved locally and refreshed once daily.
- Download button and Timer > Update Online Quotes request a fresh batch.
- A 60-second request cooldown survives relaunch; failed automatic fetches wait an hour before retrying.
- Next quote still rotates instantly from local collections without making a request.
- The original 30 quotes and previously downloaded quotes remain available offline.
- Author attributions and a ZenQuotes credit link are shown in the quote card.

## Included from v2.1

- Test sound button beside the Sound on/off control.
- Preview, system notifications, and fallback alerts share one bundled chime.
- Explicit sound previews work even when automatic transition sounds are off.
- The original TimerEnd.wav chime is included in Resources and can be redistributed with this app.

## Included from v2

- 15 Focus quotes and 15 Rest quotes, each with author and source.
- Changes every 60 seconds, including while the timer is paused.
- Next quote button and Command-N keyboard shortcut.
- Independent positions for each mode, cycling through all 15 before repeating.
- Offline quote library; author links open source websites on request.
- Compatible with v1 saved timer state.

See [Quotes.md](../Quotes.md) for the complete list and references.

## Build

Install Apple's Command Line Tools, then run `bash build.sh` in this folder.
The Apple silicon DMG is written to `dist/5217-v2.4.7-Apple-Silicon.dmg`.
No third-party packages are required. The build uses a local ad-hoc signature.
Public distribution with Apple notarization requires your own Developer ID
certificate and Apple developer account; no credentials are bundled.

## Implementation

- `Sources/TimerEngine.swift`: deterministic, Codable timer with absolute deadlines.
- `Sources/TimerModel.swift`: timer orchestration, notification scheduling and wake handling.
- `Sources/Quotes.swift`: attributed library and independently timed quote rotation.
- `Sources/OnlineQuotes.swift`: local quote cache, validation, mode sorting, cooldown and retry policy.
- `Sources/SoundController.swift`: sound selection, preparation and preview lifecycle.
- `Sources/LocalStorage.swift`: bounded JSON I/O, atomic writes and injectable paths.
- `Sources/QuoteHTTPClient.swift`: restricted, bounded HTTPS transport.
- `Sources/TimerView.swift`: SwiftUI timer and built-in transition alert.
- `Sources/main.swift`: AppKit lifecycle, menu bar, app menu, and alert panel.
- `Tests/main.swift`: 164 checks for countdown, boundaries, pause, skip, persistence,
  daily totals, multi-cycle wake reconciliation, periodic quote rotation, manual refresh, and per-mode wraparound.

The app schedules the next boundary through UserNotifications, then schedules
each subsequent boundary as the engine advances. An active ProcessInfo activity
keeps the process responsive and prevents idle system sleep. Manual sleep still
applies. Alerts cannot be guaranteed while a Mac is asleep or powered off.
Notification failures fall back to an app-owned nonactivating alert and NSSound.
Quitting pauses the timer and cancels pending system notifications.

## Validation

The production ARM64 build compiled successfully and passed all 164 timer, quote, API, and sound checks.
Native UI checks covered start/countdown, pause, skip to break, return to focus,
and the alert test action. v2.1 UI checks exercised the Test sound button with automatic sounds both on and off. The bundled 1.6-second PCM WAV is shared by previews and timer completion alerts. The app signature and DMG checksums were verified.
System notification delivery depends on macOS permissions and settings.
Intel Macs are intentionally not supported. Testing was performed on macOS 27;
earlier supported versions have not been run on physical test machines.
API tests use intercepted HTTP responses to verify success, persistent caching, cooldowns, HTTP 429, malformed JSON, and offline behavior.

See `Install 5217.txt` for installation and everyday use.

## Online quote provider and privacy

Provider: [ZenQuotes API](https://zenquotes.io/). See the [official documentation](https://docs.zenquotes.io/zenquotes-documentation/).

Endpoint: `GET https://zenquotes.io/api/quotes`. No key or account is needed. Free access requires a ZenQuotes attribution link; the app includes it. The documented shared-IP limit is five requests per 30 seconds. This client uses cached batches and a persistent minimum of 60 seconds between requests. Other devices on the same IP can still cause rate limiting; a failed request preserves saved quotes.

The app sends no timer history, session state, quotes viewed, identifiers, or credentials to the API. It uses an ephemeral URLSession with cookies and credential storage disabled. The service receives normal request metadata such as IP address and the app User-Agent. Source links open in the default browser only when clicked.

Online quotes are provider attributions, not independently verified source citations. The API does not return original books or passages. The free batch endpoint has no topic filters; local keyword matching selects likely Focus and Rest quotes. Unrelated, duplicate, malformed, and overly long entries are discarded. The exact number of matching quotes varies, and any mode without matches retains its curated set.

Caches are stored alongside timer.json in ~/Library/Application Support/5217/: online-quotes.json and quote-fetch-attempt.json. They are not included in the source archive or installer. No API content is compiled into the app.

Live integration validation on 22 October 2026: the native preview fetched and saved 9 matching Focus quotes and 1 Rest quote from ZenQuotes over HTTPS. Both collections displayed API quotes with attribution. These live results are not shipped in the installer or source archive.

## System sounds

SoundSettingsView provides a searchable in-window pane. NotificationSounds.swift discovers readable sound files on the local Mac and uses public Foundation and AVFoundation APIs to prepare them. No private ToneLibrary API is called or linked. Standard alert sounds come from /System/Library/Sounds. Additional Apple tone resources are discovered opportunistically under the installed ToneLibrary resource folders; availability and locations can change with macOS versions. The bundled chime always remains available.

Apple sound files are not included in the installer, source archive, or repository. When a tone is selected or previewed, a local PCM CAF copy is prepared in ~/Library/Sounds with a 5217- prefix. NSSound plays the prepared audio; scheduled UserNotifications banners are silent. Long tones retain the 29-second cap from earlier releases. File identities include source metadata so an updated system tone gets a new local copy.

The preference is stored in ~/Library/Application Support/5217/sound-settings.json. Existing timer.json and quote caches remain compatible. No system-wide alert settings are changed. A read/convert/save error retains the previous selection and shows a message.

Sound validation on the build Mac found 144 choices and successfully prepared all installed Apple sound files. The AAC decoder requires normal macOS service access; restricted command sandboxes may need to run the sound checks outside that sandbox. Tests use temporary directories and do not modify the user’s sound preferences.

Native UI validation: opened Settings via the gear icon and Command-comma, searched and selected Rebound and Tri-Tone, previewed both without errors, stopped a preview, and confirmed Tri-Tone was restored after quitting and relaunching. Tests used a separate preview data directory; no production timer data or system-wide sound preference was changed.

History implementation: FocusHistory.swift owns persistence and calendar summaries;
HistoryView.swift renders the independent modal. TimerModel imports old completions
and archives focus events as the timer advances. Security-Audit.md and Metrics.json
remain the historical v2.3.1 audit, not updated measurements for v2.4.
