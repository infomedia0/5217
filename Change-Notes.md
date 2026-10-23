# Changes for v2.4.4

- Backend-only quote theme filtering in QuoteClassifier.swift. Clear Focus signals:
  motivation, learning, discipline, effort, progress. Break signals: rest, calm,
  mindfulness, nature. Reject mixed themes, common negated signals, and generic
  time/today/joy-only matches rather than guessing a mode. These are conservative
  text rules, not AI or a guarantee of semantic understanding.
- Canonical text deduplication ignores case and punctuation variants.
- Separate Focus and Break arrays remain in online-quotes.json. Keep suitable old
  matches when the new batch lacks one mode; cap at 25 online quotes per mode.
  New matches come first. Global fetchedAt means last successful batch retrieval,
  not the age of each retained quote. Curated offline collections remain separate.
- Reclassify valid existing caches with the new rules; discard newly unsuitable
  entries without discarding the entire otherwise usable cache.
- Same free ZenQuotes endpoint, cooldown, daily refresh, HTTPS constraints,
  bounded downloads and private JSON persistence. No API key or database added.
- Sole layout change requested: move “Always close by, in your menu bar.” down 8px
  with an offset, preserving other element positions and window size.
- 153 automated checks passed, including 29 new quote/theme/cache checks.
- Screenshot previews use isolated state, a fixed quote and a single example
  completed session. Preview-only notification/quote freezing makes the footer
  comparison repeatable. No example state will ship.


The user approved final packaging after reviewing the screenshots.
