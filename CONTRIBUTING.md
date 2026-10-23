# Contributing

Open an issue describing the problem or proposed improvement before a large change.
For a bug, include the macOS version, app version, expected behavior and reproduction
steps. Remove personal information from screenshots and logs; do not upload timer data.

1. Fork the repository and create a branch for your change.
2. Keep timer logic, JSON persistence, networking, sound playback and UI responsibilities separate.
3. Preserve existing JSON compatibility and keep session history local.
4. Run `bash scripts/test.sh`. For UI changes, also compile and inspect the app on macOS.
5. Open a pull request describing behavior, validation and any limitations.

Use the existing Swift style. Do not add credentials, Apple sound files, downloaded
quote caches or generated installers. Quote changes should include reliable attribution.
Contributions are submitted under the repository’s MIT license.
