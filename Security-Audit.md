# 5217 v2.3.1 security and maintainability audit

Date: 22 October 2026. Compared with the retained v2.3.0 source.

## Scope and result

Reviewed all application Swift sources, persistence, quote transport/parsing,
notification scheduling, audio preparation, and build packaging. No critical or
high-severity issue was confirmed in this review. This is a source review with
focused regression and runtime checks, not a penetration-test certification.
The severities below are contextual engineering assessments.

## Findings addressed

| Finding | Assessment | Change |
| --- | --- | --- |
| Quote download checked its size only after accumulating the response | Medium, remote resource exhaustion | New streaming client cancels before its application-owned response buffer exceeds 128 KiB; checks declared length, JSON MIME, HTTP status and exact HTTPS endpoint; rejects redirects. Foundation/network internal buffers are outside this measurement. |
| Local JSON reads were unbounded and followed final-component symlinks | Medium, local robustness | Shared storage uses bounded regular-file, no-follow reads; limits timer state to 256 KiB, quote cache to 128 KiB, settings to 4 KiB, attempt timestamp to 128 bytes. |
| Persisted countdown/history values were trusted | Medium, local denial of service/incorrect totals | Validate dates, durations and history; clamp countdown before integer conversion; skip stale complete cycles arithmetically rather than iterate over years. Retain at most 31 days and 1,024 focus records. |
| Cached quote fields bypassed current input rules; future request timestamp could suppress updates | Low | Cached and downloaded text share normalization, size and control/bidi-character checks. Rebuild cache metadata with fixed provider/source. Reject future retry timestamps. |
| Data files inherited process-default permissions | Low, local privacy | New JSON files use explicit 0600, same-directory exclusive temporary files and atomic rename; newly created JSON parent directories use 0700. Existing parent directory permissions are preserved. |
| Stale notification completion could affect a newer timer | Low, correctness | Unique request identifiers and isolated delivery state ignore callbacks from canceled/replaced requests. |
| Cached audio was accepted without checking format or symlinks | Low, local robustness | Require regular non-symlink PCM16 audio, 1–2 channels, supported sample rates, at most 29 seconds and 24 MiB. Replace invalid cache entries atomically using owner-only temporary files. |
| Release executable lacked hardened runtime | Defense in depth | Enable hardened runtime on the ad-hoc signature; verify signature and arm64-only executable. |

No claim of protection against an attacker already controlling this user account:
parent-directory traversal and audio validation/open races are not a sandbox.
System tone sources are OS-owned files. Final-component no-follow JSON reads and
atomic replacements reduce accidental corruption and link-following hazards.

## Refactoring

- SoundController owns sound selection, preview lifecycle, preparation and preferences.
- QuoteHTTPClient owns one bounded request and serial delegate queue per fetch.
- LocalStorage owns JSON I/O policy. AppPaths makes state paths injectable, letting
  runtime QA use an isolated directory without modifying production model logic.
- NotificationDeliveryState expresses callback ownership separately from UI code.
- SoundCatalog loads each of four localization tables once per discovery instead
  of reloading them inside loops. Discovered choices remain unchanged on this Mac.

## Measured changes

| Metric | v2.3.0 | v2.3.1 | Change |
| --- | ---: | ---: | ---: |
| TimerModel physical lines | 315 | 238 | −77 (24.4%) |
| Largest Swift source file, lines | 315 | 238 | −24.4% |
| Automated assertions passing | 72 | 99 | +27 (37.5%) |
| Localization-table reads per discovery | 87 | 4 | −83 (95.4%) |
| Swift source files | 8 | 11 | +3 focused modules |
| Total Swift source lines | 1,215 | 1,435 | +220 (18.1%) for separation and validation |
| Installed sound choices validated | 144 | 144 | Preserved |
| Third-party packages | 0 | 0 | Unchanged |
| Hardened runtime | Off | On | Enabled |

Line counts include comments and blank lines, exclude tests/build tools. Assertions
are executable checks, not a line-coverage percentage. Table-read counts came from
instrumenting both catalogs on this same Mac. No startup-time, memory-peak or
subjective complexity improvement is claimed. Machine-readable details: Metrics.json.

## Verification

- Release compiled for arm64/macOS 13 minimum with warnings treated as errors.
- 99 assertions passed: timer transitions/pause/restore, quote parsing/cache and
  cooldown, response MIME/status/size/redirect handling, permissions/symlinks,
  malformed saved state, stale callbacks, and preparation of 144 installed tones.
- Isolated preview with separate bundle identifier and data paths: opened hardened
  executable, fetched live ZenQuotes data, searched/selected Tri-Tone, verified
  persisted selection, and started/paused a countdown with ticking seconds.
- Generated JSON and prepared audio in preview state were verified as mode 0600.
- Release app signature and DMG checksum verified. Executable is arm64 only.

## Remaining release considerations

The app is locally ad-hoc signed, not Developer ID signed or notarized. Public
release should add Developer ID signing and Apple notarization. Hardened runtime
does not replace either. App Sandbox is not enabled; the app discovers installed
system tones and writes prepared notification audio to the user's Library/Sounds.
Optional ToneLibrary resource paths can change between macOS releases; the bundled
original chime remains the fallback. Apple audio is not included in the app/source.

ZenQuotes remains a third-party availability/content dependency. HTTPS validation
uses Apple's default trust evaluation. No timer history is sent; the provider
receives connection metadata such as IP address. Local timer files are not
application-encrypted. No external dependency scanner results or vulnerability-free
claim are implied by the absence of third-party packages.

## Apple references

- [Hardened runtime](https://developer.apple.com/documentation/security/hardened-runtime)
- [Developer ID distribution](https://help.apple.com/xcode/mac/current/en.lproj/devf87a2ac8f.html)
- [URLSessionDataDelegate](https://developer.apple.com/documentation/foundation/urlsessiondatadelegate)
