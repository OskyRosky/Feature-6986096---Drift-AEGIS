"""Robust logging for the drift engine (E5B hardened).

- UTF-8 console (reconfigure stdout; avoids cp1252 UnicodeEncodeError on paths).
- Optional UTF-8 rotating file handler under V1/logs/.
- Never logs secrets, hosts, or full connection strings.
"""

from __future__ import annotations

import logging
import sys
from logging.handlers import RotatingFileHandler
from pathlib import Path

_FMT = "%(asctime)s %(levelname)s %(name)s: %(message)s"
_LOG_DIR = Path(__file__).resolve().parents[2] / "logs"  # V1/logs (gitignored)


def _make_stream_handler() -> logging.Handler:
    stream = sys.stdout
    try:  # force UTF-8 so U+2011 etc. never break a cp1252 console
        stream.reconfigure(encoding="utf-8", errors="replace")
    except Exception:  # pragma: no cover
        pass
    h = logging.StreamHandler(stream)
    h.setFormatter(logging.Formatter(_FMT))
    return h


def _make_file_handler() -> "logging.Handler | None":
    try:
        _LOG_DIR.mkdir(parents=True, exist_ok=True)
        fh = RotatingFileHandler(_LOG_DIR / "drift_engine.log", maxBytes=1_000_000,
                                 backupCount=3, encoding="utf-8")
        fh.setFormatter(logging.Formatter(_FMT))
        return fh
    except Exception:  # pragma: no cover
        return None


def get_logger(name: str = "drift_engine", level: int = logging.INFO) -> logging.Logger:
    logger = logging.getLogger(name)
    if not logger.handlers:
        logger.addHandler(_make_stream_handler())
        fh = _make_file_handler()
        if fh is not None:
            logger.addHandler(fh)
        logger.setLevel(level)
        logger.propagate = False
    return logger
