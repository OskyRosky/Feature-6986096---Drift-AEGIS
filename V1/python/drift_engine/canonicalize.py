"""Key canonicalization & case-folding (E5B, resolves I1).

The source fact table contains case/whitespace variants of the same logical
entity, e.g. ``CAN-GO LOCAL`` vs ``CAN-Go Local``. These must be treated as the
SAME entity for grouping/version-pairing, but the original value must be
preserved for lineage (never silently overwritten).

Rules applied (case + whitespace ONLY — deliberately conservative):
  1. cast to str
  2. strip leading/trailing whitespace
  3. collapse internal runs of whitespace to a single space
  4. upper-case (case-fold) for the canonical form

Two raw keys merge **only** when they are identical after (1)-(4). Keys that
differ by anything other than case/whitespace stay separate. A separate
"suspicious" guard flags any canonical group whose raw members differ by more
than case/whitespace once punctuation/spacing is removed (should never happen
by construction; surfaced for audit rather than acted upon).

No I/O, no DB. Pure pandas transforms + an auditable collision report.
"""

from __future__ import annotations

import re

import pandas as pd

_WS = re.compile(r"\s+")


def canonical_key(value) -> str:
    """Return the canonical form of a single key (str, trimmed, space-collapsed, upper)."""
    s = "" if value is None else str(value)
    s = s.strip()
    s = _WS.sub(" ", s)
    return s.upper()


def _skeleton(value: str) -> str:
    """Case/space/punct-insensitive skeleton used ONLY for the safety guard."""
    return re.sub(r"[^0-9a-z]", "", str(value).lower())


def add_canonical_keys(
    df: pd.DataFrame, key_col: str = "Key", raw_col: str = "forecast_key_raw",
    canon_col: str = "forecast_key_canonical",
) -> pd.DataFrame:
    """Add raw + canonical key columns without dropping the original.

    ``key_col`` is left untouched; ``raw_col`` preserves the exact original,
    ``canon_col`` holds the canonical form. Downstream grouping should use
    ``canon_col``.
    """
    out = df.copy()
    out[raw_col] = out[key_col].astype(str)
    out[canon_col] = out[raw_col].map(canonical_key)
    return out


def collision_report(
    df: pd.DataFrame, raw_col: str = "forecast_key_raw",
    canon_col: str = "forecast_key_canonical",
) -> dict:
    """Audit report of raw->canonical folding.

    Returns counts + the list of canonical groups that fold >1 distinct raw
    variant, plus a ``suspicious_merges`` list for canonical groups whose raw
    members disagree beyond case/whitespace (safety guard; expected empty).
    """
    pairs = df[[raw_col, canon_col]].drop_duplicates()
    n_raw = int(pairs[raw_col].nunique())
    n_canon = int(pairs[canon_col].nunique())

    grouped = pairs.groupby(canon_col)[raw_col].apply(lambda s: sorted(set(s)))
    merged = grouped[grouped.map(len) > 1]

    merges = []
    suspicious = []
    for canon, variants in merged.items():
        merges.append({"canonical": canon, "raw_variants": variants, "n_variants": len(variants)})
        skels = {_skeleton(v) for v in variants}
        if len(skels) > 1:  # differ by more than case/space -> flag, do NOT merge silently
            suspicious.append({"canonical": canon, "raw_variants": variants})

    return {
        "distinct_keys_raw": n_raw,
        "distinct_keys_canonical": n_canon,
        "keys_merged": n_raw - n_canon,
        "collision_groups": int(len(merged)),
        "merges": merges,
        "suspicious_merges": suspicious,
    }
