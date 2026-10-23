# Publication preparation review

Reviewed: 23 October 2026. App source baseline: v2.4.7.

- App source, tests and bundled resources are byte-for-byte unchanged from v2.4.7.
- Added MIT license naming Arjun Sabharwal, README, screenshot, contribution guidance,
  changelog, third-party notices, a test-only script and publishing instructions.
- Text scan found no embedded API keys, private keys, access tokens or personal
  absolute paths. The credential-looking test URL is deliberately synthetic test data.
- No runtime session JSON, downloaded quote caches, Apple system tones, signing
  credentials, build output or installers belong in the public repository.
- Offline quote attributions were retained; no fresh legal determination of every
  quoted edition’s worldwide copyright status was made. Third-party content is not
  represented as MIT-licensed project code.
- Existing installed app and release export remain unchanged. This preparation has
  not created or published a GitHub repository or rebuilt the installer.

This is a source-publication review, not a comprehensive security or legal audit.

Validation: all 164 automated checks passed; 144 installed sound choices validated.
Relative Markdown links checked successfully. Generated test artifacts removed.

Screenshot gallery: six native preview captures (Focus, Rest, History, Sounds,
Releases and About). Sample history contains 12 sessions / 10h 24m. Screenshots
use isolated dummy data, exclude the OS title/capture strip, and contain no personal
session records. Preview-only modifications are not included in app source.
