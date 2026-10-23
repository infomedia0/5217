# Changes for v2.4.5

- Footer: “To quit: menu bar → Quit 5217, or right-click the Dock icon → Quit.”
- Settings > Sounds offers 1, 5, 10 and 15 second playback limits. Default 5s.
  Applies to automatic completion sounds, Test sound, sound-selection previews,
  and the alert test. Short sounds finish naturally; no looping is added.
  Changing duration stops current audio. Stop still silences immediately.
- Duration is saved in sound-settings.json alongside the selected tone.
  Legacy preferences preserve the selected tone and default to 5 seconds.
  Unsupported or malformed durations fall back to 5 seconds.
- Playback cutoff tasks are canceled on stop/change/completion and guarded by a
  per-playback ID so an old deadline cannot cut off a later sound.
- About now explains single-task focus, genuine breaks and the observational
  basis of 52/17; five reading links are provided. See About-Sources.md.
- 164 automated regression checks passed. Separate native preview checks confirmed
  1s and 5s cutoff behavior and stale-cutoff cancellation (three checks passed).
- Native UI reviewed for duration controls, About text/links, and footer wording.

The user approved final packaging after reviewing the changes and previews.
Preview-only long audio and integration harness are outside production sources.
