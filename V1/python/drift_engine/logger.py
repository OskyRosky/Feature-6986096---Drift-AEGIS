"""Lightweight logging for the drift engine. Never logs secrets/hosts/conn strings."""

from __future__ import annotations

import logging
import sys


def get_logger(name: str = "drift_engine", level: int = logging.INFO) -> logging.Logger:
    logger = logging.getLogger(name)
    if not logger.handlers:
        h = logging.StreamHandler(sys.stdout)
        h.setFormatter(logging.Formatter("%(asctime)s %(levelname)s %(name)s: %(message)s"))
        logger.addHandler(h)
        logger.setLevel(level)
    return logger
