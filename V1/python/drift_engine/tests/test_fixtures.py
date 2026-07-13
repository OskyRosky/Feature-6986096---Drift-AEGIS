"""E3 fixture tests for the drift engine. Runs with pytest OR standalone.

Validates raw metric, normalized score, status against E3 expected values.
"""

from __future__ import annotations

import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[2]))  # V1/python

from drift_engine.families import (
    performance_drift,
    shape_drift,
    stability_drift,
    volatility_drift,
)
from drift_engine.composite import composite, is_event
from drift_engine.scoring import status_band

TOL = 1.0

FIXTURES = []


def _check(name, got, expected, tol, status_got, status_exp):
    ok = (got is not None) and abs(got - expected) <= tol and status_got == status_exp
    FIXTURES.append(
        {
            "fixture": name,
            "score_got": None if got is None else round(got, 2),
            "score_expected": expected,
            "tolerance": tol,
            "status_got": status_got,
            "status_expected": status_exp,
            "result": "PASS" if ok else "FAIL",
        }
    )
    return ok


def test_performance():
    step1 = performance_drift(0.45, 0.44)  # +0.01 below gate
    assert _check("FX-PERF-01", step1["score"], 0.0, TOL, status_band(step1["score"]), "Healthy")
    step2 = performance_drift(0.70, 0.45)
    assert _check("FX-PERF-02", step2["score"], 73.3, TOL, status_band(step2["score"]), "Critical")


def test_shape():
    r = shape_drift([100, 105, 110, 115], [100, 108, 130, 165])
    assert _check("FX-SHAPE-01", r["score"], 77.6, TOL, status_band(r["score"]), "Critical")


def test_stability():
    r = stability_drift([120, 122, 121, 156])
    assert _check("FX-STAB-01", r["score"], 86.7, TOL, status_band(r["score"]), "Critical")


def test_volatility():
    r = volatility_drift([100, 102, 101, 99, 101, 160])
    assert _check("FX-VOL-01", r["score"], 83.9, TOL, status_band(r["score"]), "Critical")


def test_composite():
    scores = {"performance": 73.3, "shape": 77.6, "stability": 86.7, "volatility": 83.9}
    c = composite(scores)
    assert _check("FX-COMP-01", c["forecast_drift_score"], 80.1, TOL, c["drift_status"], "Critical")
    assert c["dominant_drift_family"] == "shape"
    # missing volatility -> renormalize
    scores2 = {"performance": 73.3, "shape": 77.6, "stability": 86.7, "volatility": None}
    c2 = composite(scores2)
    assert _check("FX-COMP-02", c2["forecast_drift_score"], 79.7, TOL, c2["drift_status"], "Critical")
    assert c2["confidence_level"] == "HIGH" and c2["missing_family_flag"] == "volatility"


def run_all():
    for fn in (test_performance, test_shape, test_stability, test_volatility, test_composite):
        fn()
    return FIXTURES


if __name__ == "__main__":
    import csv

    from drift_engine.logger import ensure_utf8_stdout
    ensure_utf8_stdout()  # I2: safe on cp1252 consoles

    rows = run_all()
    for r in rows:
        print(r["fixture"], r["result"], r["score_got"], "vs", r["score_expected"], r["status_got"])
    n_pass = sum(1 for r in rows if r["result"] == "PASS")
    print(f"\n{n_pass}/{len(rows)} fixtures PASS")
    out = Path(__file__).resolve().parents[3] / "data" / "processed" / "validation" / "_fixture_results.csv"
    out.parent.mkdir(parents=True, exist_ok=True)
    with out.open("w", newline="", encoding="utf-8") as f:
        w = csv.DictWriter(f, fieldnames=list(rows[0].keys()))
        w.writeheader()
        w.writerows(rows)
    print("wrote", out.name)  # relative name only (no U+2011 path to console)
    sys.exit(0 if n_pass == len(rows) else 1)
