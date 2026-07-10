# AEGIS Forecast Drift Framework

**Feature 6986096 — Integrate Cross-Functional Capacity Feedback Signals to Align and Improve Capacity Mitigation Actions**

## Purpose

Forecast Accuracy measures how well a forecast performed against actuals *after the fact*.
**Forecast Drift** measures something different and complementary: whether the forecast **itself** is
changing materially over time — across versions, trajectory, and stability — often **before** actuals
even exist. The goal is to detect meaningful shifts early enough to act on them, before they surface as
capacity hotspots or force reactive mitigation.

AEGIS produces the intelligence: it **captures, calculates, and publishes** governed Forecast Drift and
Forecast Deviation signals in a queryable form. Planning, Monitoring, MDG, and future systems consume the
same governed output. This is designed as an **extensible framework** — four drift families today
(Performance, Shape, Stability, Volatility), more in the future, without redesigning the architecture.

## Current Stage

**V0.1 — Local Git Repository Initialization**
Discovery has been completed and the repository baseline has been initialized.

## Delivery Strategy

| Version | Scope | Goal |
| --- | --- | --- |
| **V1** | Power BI MVP | Validate calculations, data model, metrics, visualizations, and business logic. Power BI is the fastest path to validate the framework, not the final product. |
| **V2** | Grafana MVP | Recreate the validated logic as the production-oriented monitoring platform. |
| **V3** | Future enhancements | SQL publication, alerts, Forecast Drift Events, operational signals, hotspot correlation, ML-based detection, and downstream consumers. |

## Main Existing Artifacts

- **AEGIS Forecasting Drift Blueprint** — the conceptual framework and primary source of truth.
- **AEGIS_Forecast_Drift_Prototype.html** — the UX prototype defining the target user experience.
- **V1 / V2 / V3** — phase folders reserved for versioned implementation artifacts.

## Security Classification

> **Microsoft internal / confidential.**
> This repository contains Microsoft internal material. Do **not** publish it, push it to a personal
> account, or configure a public remote. A private Microsoft corporate remote may be added later, only
> after the correct organization and repository location are confirmed. Do not commit credentials,
> server names, tokens, connection strings, or access details.

## Status

- **Discovery:** Completed.
- **Repository baseline:** Initialized.

## Next Planned Stage

**Source-data profiling** — validate the AX / Tesseract / AEGIS Forecast Accuracy source fields
(forecast version, forecast date, target date, scenario, key, forecast value, actual value, existing
accuracy metrics, and TTL where available) before any drift calculation is designed.
