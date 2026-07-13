"""Central configuration for the Forecast Drift engine (E5A).

All parameters trace back to E3 (E3_threshold_and_normalization_config.csv) and
E4 (physical contract). No secrets, hosts, or connection strings live here.

Reuse note: connection approach adapted (not copied) from the Code Improvement
project ingestion/config.py (Entra ID Interactive, ODBC Driver 18).
"""

from __future__ import annotations

import os
from dataclasses import dataclass, field
from pathlib import Path

# ---------------------------------------------------------------------------
# Versions (written into every governed output for lineage/reproducibility)
# ---------------------------------------------------------------------------
CALCULATION_VERSION = "E5A-v1"
FORMULA_VERSION = "f1.0"
NORMALIZATION_VERSION = "piecewise-1.0"
THRESHOLD_CONFIG_VERSION = "t1.0"
WEIGHT_CONFIG_VERSION = "w1.0"

# ---------------------------------------------------------------------------
# Source objects (design names; connection host/db come from env, never here)
# ---------------------------------------------------------------------------
SOURCE_SCHEMA = "dbo"
FACT_TABLE = "forecast_substrateBE_hdd_region"
METRICS_TABLE = "forecast_substrateBE_hdd_region_metrics"

# ---------------------------------------------------------------------------
# Scope (MVP per E1B/E2: Enterprise scenario, HDD resource)
# ---------------------------------------------------------------------------
SCENARIO_SCOPE = "Enterprise"
RESOURCE_SCOPE = "HDD"
VALUE_TYPE = "Forecast-Mean"
ACTUAL_MODEL_VERSION = "actual"

# Data quality: the duplicated load (E1B gap G1)
DUPLICATE_FORECAST_VERSION = "2025-06-01"

# ---------------------------------------------------------------------------
# E3 family weights (sum must be 100)
# ---------------------------------------------------------------------------
WEIGHTS = {
    "performance": 20.0,
    "shape": 40.0,
    "stability": 30.0,
    "volatility": 10.0,
}

# E3 normalization anchors per family (a20, a40, a70, a100)
ANCHORS = {
    "performance": (0.10, 0.25, 0.50, 1.00),
    "shape": (0.05, 0.10, 0.20, 0.40),
    "stability": (0.03, 0.07, 0.15, 0.40),
    "volatility": (0.03, 0.07, 0.15, 0.30),
}

# E3 severity bands (inclusive lower, exclusive upper; Critical top inclusive)
BANDS = {"watch_min": 20.0, "warning_min": 40.0, "critical_min": 70.0}

# E3 eligibility / gates
EPS = 1e-6
PERF_MIN_ABS_DELTA = 0.02
SHAPE_MIN_POINTS = 4
SHAPE_DIV_PCT = 0.05
STAB_JUMP_PCT = 0.15
STAB_MIN_ABS = 1.0
VOL_WINDOW_N = 6
MIN_VERSIONS = {"performance": 2, "shape": 2, "stability": 2, "volatility": 4}

# E3 composite/event params
EVENT_THRESHOLD = 40.0
FAMILY_EVENT_THRESHOLD = 70.0
PERSISTENCE_MIN = 2
COOLDOWN_VERSIONS = 1
CONTRIB_MIN_PCT = 15.0
# NOTE (E3 reconciliation): E3 config CSV had confidence_high_coverage=100, but the
# E3 fixture FX-COMP-02 (coverage 90%) expected HIGH. Harmonized here to HIGH>=90.
CONFIDENCE_HIGH_COVERAGE = 90.0
CONFIDENCE_MEDIUM_COVERAGE = 60.0

FAMILIES = ("performance", "shape", "stability", "volatility")


@dataclass
class SampleConfig:
    """Controlled real-sample run parameters (read-only).

    E5A default = 3 keys / 8 versions. E5B expanded (still controlled, NOT full
    history) = ``SampleConfig.expanded()`` -> 12 keys / 15 versions.
    ``perf_mode`` selects the Performance source: 'shallow' (official metrics,
    E5A) or 'deep' (MAPE recomputed from forecasts+actuals, E5B/I3).
    """

    scenario: str = SCENARIO_SCOPE
    resource: str = RESOURCE_SCOPE
    n_keys: int = 3
    n_versions: int = 8
    keys: list[str] = field(default_factory=list)  # empty => auto-pick top keys
    perf_mode: str = "shallow"

    @classmethod
    def expanded(cls) -> "SampleConfig":
        """E5B expanded-but-controlled sample (Enterprise/HDD, 12 keys, 15 versions)."""
        return cls(n_keys=12, n_versions=15, perf_mode="shallow")


@dataclass
class Paths:
    """Output paths (Drift project V1/data/processed)."""

    root: Path = Path(__file__).resolve().parents[3]  # .../V1
    processed: Path = None

    def __post_init__(self) -> None:
        self.processed = self.root / "data" / "processed"
        self.processed.mkdir(parents=True, exist_ok=True)


def sql_server() -> str:
    """SQL server host from env (never hard-coded in repo)."""
    return os.environ.get("AEGIS_DRIFT_SQL_SERVER", "")


def sql_database() -> str:
    return os.environ.get("AEGIS_DRIFT_SQL_DATABASE", "")
