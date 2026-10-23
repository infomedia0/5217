# Changes for v2.4.6

- Quotes open expanded on every launch, matching the current default.
- Hide quotes collapses content and quote actions into a compact bar with Show quotes.
- The timer window shortens while quotes are hidden; its top edge stays in place.
- Settings/History/confirmation retain their full-size layout. Returning to the
  timer restores the collapsed size if applicable. Visibility is session-only.
- Collapsing changes presentation only: countdown, quote rotation, cached quotes,
  session history and sound settings are unaffected.

The user approved final packaging after reviewing the expanded/collapsed previews.

Validation: warnings-as-errors Swift compilation passed. Native UI checks confirmed
expanded-by-default launch, collapse/expand during a running countdown, Settings
and History navigation, hidden state across phase changes, and expanded state
after quitting while collapsed. Screenshots measured 460×817 expanded/relaunch
and 460×706 collapsed, retaining width and reducing height by 111 pixels.
