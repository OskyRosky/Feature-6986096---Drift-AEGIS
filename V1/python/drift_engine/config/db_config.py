"""Read-only DB connection config for the Drift engine.

Adapted (not copied) from Code Improvement ingestion/config.py:
Microsoft Entra ID authentication only; no passwords/secrets in code.
Host and database are read from environment variables so the repository never
stores a server name or connection string (governance requirement).
"""

from __future__ import annotations

from .settings import sql_server, sql_database

ODBC_DRIVER = "ODBC Driver 18 for SQL Server"
AUTH_INTERACTIVE = "ActiveDirectoryInteractive"


def build_connection_string(authentication: str = AUTH_INTERACTIVE) -> str:
    """Build a pyodbc connection string for Azure SQL via Entra ID.

    Requires env vars AEGIS_DRIFT_SQL_SERVER and AEGIS_DRIFT_SQL_DATABASE.
    """
    server = sql_server()
    database = sql_database()
    if not server or not database:
        raise RuntimeError(
            "Set AEGIS_DRIFT_SQL_SERVER and AEGIS_DRIFT_SQL_DATABASE env vars "
            "(host is never stored in the repo)."
        )
    return (
        f"Driver={{{ODBC_DRIVER}}};"
        f"Server=tcp:{server},1433;"
        f"Database={database};"
        "Encrypt=yes;"
        "TrustServerCertificate=no;"
        "Connection Timeout=30;"
        f"Authentication={authentication};"
    )
