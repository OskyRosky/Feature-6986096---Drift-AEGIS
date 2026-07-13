# E6 — Sidebar & Navigation Specification

**Feature 6986096 — AEGIS Forecast Drift Framework.** Date: 2026-07-13.

## Sidebar (left rail, ~220 px, on every page)
Replicates the mockup. Not required to be collapsible.

| Order | Label | Target page | Icon (suggested) |
| --- | --- | --- | --- |
| — | **AEGIS** (logo/wordmark) | — (home = Overview) | shield/pulse |
| 1 | Overview | Overview | grid |
| 2 | Forecast Drift | Forecast Drift | activity |
| 3 | Performance Drift | Performance Drift | gauge |
| 4 | Shape Drift | Shape Drift | wave |
| 5 | Stability Drift | Stability Drift | anchor |
| 6 | Volatility Drift | Volatility Drift | zigzag |
| 7 | Forecast Drift Events | Forecast Drift Events | bell |
| 8 | Historical Timeline | Historical Timeline | clock |
| 9 | Top Services | Top Services | server |
| 10 | Top Scenarios | Top Scenarios | layers |
| 11 | Settings | Settings / Data Status | cog |

## Implementation (Power BI Desktop, manual)
- Build the rail once on a blank page, then **copy to all pages** (or use a
  reusable group). Recommended: **buttons** with `Page navigation` action per
  item (simplest, reliable), or a single **Navigator** visual.
- Active-state: use two bookmarks per item (default / selected) OR button states
  (Default/Pressed) to highlight the current page.
- Group the buttons; align left; consistent 40–44 px row height; sober palette
  (dark rail `#1F2A37`, text `#E5E7EB`, active accent `#3B82F6`).
- Optional top bar: report title + "Last refresh: [Latest Refresh]" caption.

## Bookmarks
- One bookmark per page for the navigator highlight (optional).
- Optional "Reset filters" bookmark clearing the shared slicers.

## Notes
- Page navigation buttons need no DAX and introduce no business logic.
- Keep page display names matching the sidebar labels for clarity.
