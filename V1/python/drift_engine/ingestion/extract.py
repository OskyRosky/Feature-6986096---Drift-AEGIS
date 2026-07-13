"""Read-only extraction from Tesseract for the controlled sample.

Every function runs SELECT only via pyodbc. Returns pandas DataFrames.
"""

from __future__ import annotations

import pandas as pd
import pyodbc

from ..config.db_config import build_connection_string
from ..config.settings import (
    ACTUAL_MODEL_VERSION,
    RESOURCE_SCOPE,
    SCENARIO_SCOPE,
    VALUE_TYPE,
)
from ..logger import get_logger
from . import queries as Q

log = get_logger("drift_engine.extract")


def _connect():
    return pyodbc.connect(build_connection_string(), timeout=60)


def _fetch_df(cur, sql, params) -> pd.DataFrame:
    """Execute a SELECT and build a DataFrame from cursor (avoids read_sql overhead)."""
    cur.execute(sql, *params)
    cols = [d[0] for d in cur.description]
    rows = cur.fetchall()
    return pd.DataFrame.from_records([tuple(r) for r in rows], columns=cols)


def extract_sample(n_keys: int, n_versions: int, keys: list[str] | None = None) -> dict:
    """Extract forecasts, actuals, metrics for a small governed sample (read-only)."""
    with _connect() as conn:
        cur = conn.cursor()
        # 1) latest versions
        cur.execute(Q.LATEST_VERSIONS, n_versions, SCENARIO_SCOPE, VALUE_TYPE, ACTUAL_MODEL_VERSION)
        versions = [r[0] for r in cur.fetchall()]
        log.info("versions selected: %s", len(versions))
        # 2) keys
        if not keys:
            cur.execute(Q.TOP_KEYS, n_keys, SCENARIO_SCOPE, RESOURCE_SCOPE, VALUE_TYPE, ACTUAL_MODEL_VERSION)
            keys = [r[0] for r in cur.fetchall()]
        log.info("keys selected: %s", keys)
        # 3) forecasts
        fq = Q.forecasts_query(len(keys), len(versions))
        params = [SCENARIO_SCOPE, RESOURCE_SCOPE, VALUE_TYPE, ACTUAL_MODEL_VERSION, *keys, *versions]
        forecasts = _fetch_df(cur, fq, params)
        log.info("forecast rows: %s", len(forecasts))
        # 4) actuals
        aq = Q.actuals_query(len(keys))
        aparams = [SCENARIO_SCOPE, RESOURCE_SCOPE, VALUE_TYPE, ACTUAL_MODEL_VERSION, *keys]
        actuals = _fetch_df(cur, aq, aparams)
        log.info("actual rows: %s", len(actuals))
        # 5) metrics
        mq = Q.metrics_query(len(keys))
        metrics = _fetch_df(cur, mq, list(keys))
        log.info("metric rows: %s", len(metrics))
    return {
        "keys": keys,
        "versions": versions,
        "forecasts": forecasts,
        "actuals": actuals,
        "metrics": metrics,
    }
