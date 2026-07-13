"""Read-only, parameterized SELECT queries for the Drift engine.

SELECT only. No writes. Object names from config.settings. Values passed as
pyodbc parameters (never string-formatted) to avoid injection.
"""

from __future__ import annotations

from ..config.settings import FACT_TABLE, METRICS_TABLE, SOURCE_SCHEMA

_FQ = f"[{SOURCE_SCHEMA}].[{FACT_TABLE}]"
_FQM = f"[{SOURCE_SCHEMA}].[{METRICS_TABLE}]"

# Latest N forecast versions for a scenario (read-only)
LATEST_VERSIONS = f"""
SELECT DISTINCT TOP (?) [ForecastVersion]
FROM {_FQ}
WHERE [Scenario] = ? AND [ValueType] = ? AND [ModelVersion] <> ?
ORDER BY [ForecastVersion] DESC;
"""

# Top keys by row count for a scenario/resource (read-only)
TOP_KEYS = f"""
SELECT TOP (?) [Key], COUNT(*) AS c
FROM {_FQ}
WHERE [Scenario] = ? AND [Resource] = ? AND [ValueType] = ? AND [ModelVersion] <> ?
GROUP BY [Key]
ORDER BY c DESC;
"""


def forecasts_query(n_keys: int, n_versions: int) -> str:
    """Forecast values for the sample keys/versions (parameters supplied by caller)."""
    keyph = ",".join(["?"] * n_keys)
    verph = ",".join(["?"] * n_versions)
    return f"""
SELECT [Key], [DateTime] AS target_date, [ForecastVersion] AS forecast_version,
       [Value] AS forecast_value, [ModelVersion] AS model_version,
       [Scenario], [Resource]
FROM {_FQ}
WHERE [Scenario] = ? AND [Resource] = ? AND [ValueType] = ? AND [ModelVersion] <> ?
  AND [Key] IN ({keyph}) AND [ForecastVersion] IN ({verph})
ORDER BY [Key], [ForecastVersion], [DateTime];
"""


def actuals_query(n_keys: int) -> str:
    keyph = ",".join(["?"] * n_keys)
    return f"""
SELECT [Key], [DateTime] AS target_date, [Value] AS actual_value, [Scenario], [Resource]
FROM {_FQ}
WHERE [Scenario] = ? AND [Resource] = ? AND [ValueType] = ? AND [ModelVersion] = ? AND [Value] > 0
  AND [Key] IN ({keyph})
ORDER BY [Key], [DateTime];
"""


def metrics_query(n_keys: int) -> str:
    keyph = ",".join(["?"] * n_keys)
    return f"""
SELECT [Key], [Forecast_Version] AS forecast_version, [MAPE], [Bias], [Bias_Pct],
       [Accuracy], [MAE], [RMSE], [SMAPE], [Start_Date], [End_Date]
FROM {_FQM}
WHERE [Key] IN ({keyph})
ORDER BY [Key], [Forecast_Version];
"""
