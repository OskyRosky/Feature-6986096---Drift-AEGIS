# E5B — Key Canonicalization Report (resolves I1)

**Feature 6986096 — AEGIS Forecast Drift Framework.** Date: 2026-07-13.

## Problem (I1)
The source fact table contains case/whitespace variants of the same logical
entity, e.g. `CAN-GO LOCAL` vs `CAN-Go Local`. If treated as distinct, a single
key's version history is split, distinct-key counts inflate, and version pairing
(the basis of Shape/Stability/Volatility drift) breaks.

## Rule applied (conservative — case + whitespace ONLY)
Implemented in `V1/python/drift_engine/canonicalize.py`:
1. cast to `str`;
2. `strip()` leading/trailing whitespace;
3. collapse internal whitespace runs to a single space (`\s+` → `" "`);
4. upper-case (case-fold).

Two raw keys **merge only** when identical after (1)–(4). Anything differing by
more than case/whitespace stays separate.

## Non-destructive design
- `forecast_key_raw` preserves the exact original value (lineage).
- `forecast_key_canonical` holds the canonical form.
- Grouping/version-pairing uses the canonical form; the raw value is **never
  silently overwritten**. Signals carry the most frequent raw spelling in
  `forecast_key_raw`.

## Safety guard against wrong merges
`collision_report()` computes a case/space/punctuation-insensitive "skeleton"
for every raw member of a canonical group; if two members disagree beyond
case/whitespace they are surfaced under `suspicious_merges` (audited, not merged
silently). Expected empty.

## Result (deterministic synthetic fixture, seed 42)
| Metric | Value |
| --- | --- |
| distinct_keys_raw | 9 |
| distinct_keys_canonical | 7 |
| keys_merged | 2 |
| collision_groups | 1 |
| suspicious_merges | 0 |

Merged group:
`CAN-GO LOCAL` ← `['  can-go local ', 'CAN-GO LOCAL', 'CAN-Go Local']`

## Impact
- **Grain:** grouping key becomes canonical; per-key history is no longer split.
- **Counts:** distinct entity count drops from raw to canonical (here 9→7).
- **Signals/events:** version pairs that were previously separated by casing are
  now compared, so drift is computed on the true entity history (more, and
  correct, signals per entity).

## Live confirmation (operator DB run, 2026-07-13) — COMPLETED
The expanded live read-only run confirmed the real fact-table variant volume:

| Metric | Value (live) |
| --- | --- |
| distinct_keys_raw | 21 |
| distinct_keys_canonical | 12 |
| keys_merged | 9 |
| collision_groups | 9 |
| suspicious_merges | 0 |

So the real Enterprise/HDD sample carried **9 case/whitespace duplicate keys**
that E5A's destructive upper-casing would have de-cased silently; E5B now audits
and reports them (emitted in `run_metadata.json.normalization_stats` /
`key_collision_report`). Same numbers on both live runs (idempotent).
