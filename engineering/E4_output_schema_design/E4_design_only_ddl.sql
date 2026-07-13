/* ============================================================================
   AEGIS Forecast Drift Framework — Feature 6986096
   E4 Output Schema — DESIGN ONLY — DO NOT EXECUTE
   This file is a physical design proposal. It is NOT to be run in any database.
   No DDL has been executed. Types/constraints/indexes are for review only.
   Deployment order (when eventually authorized in E5): config -> run -> signals
   -> family_scores -> event_history -> indexes -> views.
   ============================================================================ */

-- ############################################################################
-- 1) CONFIG TABLES
-- ############################################################################

-- DESIGN ONLY — DO NOT EXECUTE
CREATE TABLE dbo.aegis_drift_formula_config (
    formula_version        VARCHAR(20)   NOT NULL,
    normalization_method   VARCHAR(40)   NOT NULL,
    event_threshold        DECIMAL(5,2)  NOT NULL CONSTRAINT DF_fc_evt DEFAULT (40),
    family_event_threshold DECIMAL(5,2)  NOT NULL CONSTRAINT DF_fc_fevt DEFAULT (70),
    persistence_min        INT           NOT NULL CONSTRAINT DF_fc_pmin DEFAULT (2),
    cooldown_versions      INT           NOT NULL CONSTRAINT DF_fc_cd DEFAULT (1),
    missing_family_policy   VARCHAR(40)   NOT NULL CONSTRAINT DF_fc_mfp DEFAULT ('renormalize_available'),
    description            VARCHAR(500)  NULL,
    effective_from         DATE          NOT NULL,
    effective_to           DATE          NULL,
    is_active              BIT           NOT NULL CONSTRAINT DF_fc_active DEFAULT (1),
    CONSTRAINT PK_aegis_drift_formula_config PRIMARY KEY (formula_version),
    CONSTRAINT CK_fc_thresholds CHECK (event_threshold BETWEEN 0 AND 100 AND family_event_threshold BETWEEN 0 AND 100)
);

-- DESIGN ONLY — DO NOT EXECUTE
CREATE TABLE dbo.aegis_drift_threshold_config (
    threshold_config_id INT IDENTITY(1,1) NOT NULL,
    config_version      VARCHAR(20)  NOT NULL,
    drift_family        VARCHAR(20)  NOT NULL,
    metric_name         VARCHAR(30)  NULL,
    anchor_a20          DECIMAL(9,4) NOT NULL,
    anchor_a40          DECIMAL(9,4) NOT NULL,
    anchor_a70          DECIMAL(9,4) NOT NULL,
    anchor_a100         DECIMAL(9,4) NOT NULL,
    band_watch_min      DECIMAL(5,2) NOT NULL CONSTRAINT DF_tc_watch DEFAULT (20),
    band_warning_min    DECIMAL(5,2) NOT NULL CONSTRAINT DF_tc_warn DEFAULT (40),
    band_critical_min   DECIMAL(5,2) NOT NULL CONSTRAINT DF_tc_crit DEFAULT (70),
    min_versions        INT          NOT NULL CONSTRAINT DF_tc_minv DEFAULT (2),
    window_n            INT          NULL,
    gate_value          DECIMAL(9,4) NULL,
    effective_from      DATE         NOT NULL,
    effective_to        DATE         NULL,
    is_active           BIT          NOT NULL CONSTRAINT DF_tc_active DEFAULT (1),
    approved_by         VARCHAR(100) NULL,
    created_at          DATETIME2(3) NOT NULL CONSTRAINT DF_tc_ca DEFAULT (SYSUTCDATETIME()),
    created_by          VARCHAR(100) NOT NULL,
    CONSTRAINT PK_aegis_drift_threshold_config PRIMARY KEY (threshold_config_id),
    CONSTRAINT UQ_threshold_config UNIQUE (config_version, drift_family, metric_name),
    CONSTRAINT CK_threshold_anchor_order CHECK (anchor_a20 < anchor_a40 AND anchor_a40 < anchor_a70 AND anchor_a70 < anchor_a100),
    CONSTRAINT CK_threshold_family CHECK (drift_family IN ('performance','shape','stability','volatility')),
    CONSTRAINT CK_threshold_effective CHECK (effective_to IS NULL OR effective_to > effective_from)
);
-- one active config per family/metric (filtered unique)
-- DESIGN ONLY — DO NOT EXECUTE
CREATE UNIQUE INDEX UX_threshold_active ON dbo.aegis_drift_threshold_config (drift_family, metric_name) WHERE is_active = 1;

-- DESIGN ONLY — DO NOT EXECUTE
CREATE TABLE dbo.aegis_drift_weight_config (
    weight_config_id INT IDENTITY(1,1) NOT NULL,
    config_version   VARCHAR(20)  NOT NULL,
    drift_family     VARCHAR(20)  NOT NULL,
    weight_pct       DECIMAL(5,2) NOT NULL,
    effective_from   DATE         NOT NULL,
    effective_to     DATE         NULL,
    is_active        BIT          NOT NULL CONSTRAINT DF_wc_active DEFAULT (1),
    created_at       DATETIME2(3) NOT NULL CONSTRAINT DF_wc_ca DEFAULT (SYSUTCDATETIME()),
    created_by       VARCHAR(100) NOT NULL,
    CONSTRAINT PK_aegis_drift_weight_config PRIMARY KEY (weight_config_id),
    CONSTRAINT UQ_weight_config UNIQUE (config_version, drift_family),
    CONSTRAINT CK_weight_range CHECK (weight_pct BETWEEN 0 AND 100),
    CONSTRAINT CK_weight_family CHECK (drift_family IN ('performance','shape','stability','volatility'))
);
-- BUSINESS RULE (cross-row, enforced by app/trigger, not a table CHECK):
-- SUM(weight_pct) per config_version = 100.

-- ############################################################################
-- 2) RUN (lineage / idempotency anchor)
-- ############################################################################
-- DESIGN ONLY — DO NOT EXECUTE
CREATE TABLE dbo.aegis_forecast_drift_run (
    calculation_run_id          BIGINT IDENTITY(1,1) NOT NULL,
    calculation_version         VARCHAR(20)  NOT NULL,
    formula_version             VARCHAR(20)  NOT NULL,
    threshold_config_id         INT          NOT NULL,
    weight_config_id            INT          NOT NULL,
    run_started_at              DATETIME2(3) NOT NULL,
    run_finished_at             DATETIME2(3) NULL,
    source_forecast_version_max DATE         NULL,
    signals_written             BIGINT       NULL,
    events_created              BIGINT       NULL,
    run_status                  VARCHAR(20)  NOT NULL,
    created_by                  VARCHAR(100) NOT NULL,
    CONSTRAINT PK_aegis_forecast_drift_run PRIMARY KEY (calculation_run_id),
    CONSTRAINT CK_run_status CHECK (run_status IN ('Success','Failed','Partial')),
    CONSTRAINT FK_run_formula   FOREIGN KEY (formula_version)     REFERENCES dbo.aegis_drift_formula_config (formula_version),
    CONSTRAINT FK_run_threshold FOREIGN KEY (threshold_config_id) REFERENCES dbo.aegis_drift_threshold_config (threshold_config_id),
    CONSTRAINT FK_run_weight    FOREIGN KEY (weight_config_id)    REFERENCES dbo.aegis_drift_weight_config (weight_config_id)
);

-- ############################################################################
-- 3) MAIN SIGNAL / EVENT TABLE
-- ############################################################################
-- DESIGN ONLY — DO NOT EXECUTE
CREATE TABLE dbo.aegis_forecast_drift_signals (
    drift_event_id            BIGINT IDENTITY(1,1) NOT NULL,      -- surrogate PK
    event_natural_key         VARCHAR(300) NOT NULL,             -- readable natural key
    record_hash               BINARY(32)   NOT NULL,             -- idempotency hash
    calculation_run_id        BIGINT       NOT NULL,
    calculation_version       VARCHAR(20)  NOT NULL,
    detected_on               DATETIME2(3) NOT NULL CONSTRAINT DF_s_det DEFAULT (SYSUTCDATETIME()),
    -- dimensional context (denormalized; dim FKs deferred)
    scenario                  VARCHAR(50)  NOT NULL,
    forecast_key              VARCHAR(100) NOT NULL,
    service                   VARCHAR(100) NULL,                 -- pending G3
    region                    VARCHAR(50)  NULL,                 -- derived
    forest                    VARCHAR(50)  NULL,                 -- pending G4
    resource                  VARCHAR(20)  NOT NULL CONSTRAINT DF_s_res DEFAULT ('HDD'),
    forecast_version          DATE         NOT NULL,
    previous_forecast_version DATE         NULL,
    forecast_date             DATE         NULL,
    target_date               DATE         NULL,
    window_start_date         DATE         NULL,
    window_end_date           DATE         NULL,
    -- classification
    drift_type                VARCHAR(20)  NOT NULL,
    dominant_drift_family     VARCHAR(20)  NULL,
    drift_status              VARCHAR(20)  NOT NULL,
    severity                  VARCHAR(20)  NULL,
    persistence_type          VARCHAR(20)  NULL,
    event_status              VARCHAR(20)  NULL,
    is_event                  BIT          NOT NULL CONSTRAINT DF_s_isevt DEFAULT (0),
    -- headline source metric (dominant family)
    metric_name               VARCHAR(30)  NULL,
    metric_value              DECIMAL(18,6) NULL,
    previous_metric_value     DECIMAL(18,6) NULL,
    metric_delta              DECIMAL(18,6) NULL,
    metric_delta_pct          DECIMAL(9,4) NULL,
    -- scores
    performance_drift_score   DECIMAL(5,2) NULL,
    shape_drift_score         DECIMAL(5,2) NULL,
    stability_drift_score     DECIMAL(5,2) NULL,
    volatility_drift_score    DECIMAL(5,2) NULL,
    forecast_drift_score      DECIMAL(5,2) NOT NULL,
    score_coverage_pct        DECIMAL(5,2) NOT NULL,
    confidence_level          VARCHAR(10)  NOT NULL,
    missing_family_flag       VARCHAR(50)  NULL,
    -- explainability
    reason_code               VARCHAR(40)  NULL,
    explanation               VARCHAR(1000) NULL,
    recommended_action        VARCHAR(400) NULL,
    -- lineage / audit
    source_database           VARCHAR(128) NOT NULL,
    source_schema             VARCHAR(128) NOT NULL CONSTRAINT DF_s_sch DEFAULT ('dbo'),
    source_object             VARCHAR(128) NOT NULL,
    source_forecast_version   DATE         NULL,
    source_row_count          BIGINT       NULL,
    normalization_version     VARCHAR(20)  NOT NULL,
    formula_version           VARCHAR(20)  NOT NULL,
    threshold_config_id       INT          NOT NULL,
    weight_config_id          INT          NOT NULL,
    created_at                DATETIME2(3) NOT NULL CONSTRAINT DF_s_ca DEFAULT (SYSUTCDATETIME()),
    created_by                VARCHAR(100) NOT NULL CONSTRAINT DF_s_cb DEFAULT (SUSER_SNAME()),
    updated_at                DATETIME2(3) NULL,
    updated_by                VARCHAR(100) NULL,
    is_current                BIT          NOT NULL CONSTRAINT DF_s_cur DEFAULT (1),
    CONSTRAINT PK_aegis_forecast_drift_signals PRIMARY KEY CLUSTERED (drift_event_id),
    CONSTRAINT UQ_signals_natural UNIQUE (calculation_version, scenario, forecast_key, forecast_version, drift_type),
    CONSTRAINT UQ_signals_hash UNIQUE (record_hash),
    CONSTRAINT CK_s_scores CHECK (
        (performance_drift_score IS NULL OR performance_drift_score BETWEEN 0 AND 100) AND
        (shape_drift_score       IS NULL OR shape_drift_score       BETWEEN 0 AND 100) AND
        (stability_drift_score   IS NULL OR stability_drift_score   BETWEEN 0 AND 100) AND
        (volatility_drift_score  IS NULL OR volatility_drift_score  BETWEEN 0 AND 100) AND
        (forecast_drift_score    BETWEEN 0 AND 100) AND
        (score_coverage_pct      BETWEEN 0 AND 100)),
    CONSTRAINT CK_s_status   CHECK (drift_status IN ('Healthy','Watch','Warning','Critical')),
    CONSTRAINT CK_s_severity CHECK (severity IS NULL OR severity IN ('Watch','Warning','Critical')),
    CONSTRAINT CK_s_type     CHECK (drift_type IN ('performance','shape','stability','volatility','composite')),
    CONSTRAINT CK_s_conf     CHECK (confidence_level IN ('HIGH','MEDIUM','LOW')),
    CONSTRAINT CK_s_evtstat  CHECK (event_status IS NULL OR event_status IN ('Open','Acknowledged','Investigating','Resolved','Suppressed')),
    CONSTRAINT FK_signals_run       FOREIGN KEY (calculation_run_id)  REFERENCES dbo.aegis_forecast_drift_run (calculation_run_id),
    CONSTRAINT FK_signals_formula   FOREIGN KEY (formula_version)     REFERENCES dbo.aegis_drift_formula_config (formula_version),
    CONSTRAINT FK_signals_threshold FOREIGN KEY (threshold_config_id) REFERENCES dbo.aegis_drift_threshold_config (threshold_config_id),
    CONSTRAINT FK_signals_weight    FOREIGN KEY (weight_config_id)    REFERENCES dbo.aegis_drift_weight_config (weight_config_id)
    -- Optional dim FKs (scenario/forecast_key/service/forest/region) DEFERRED until dims materialized.
);

-- ############################################################################
-- 4) FAMILY SCORES (detail, tidy long)
-- ############################################################################
-- DESIGN ONLY — DO NOT EXECUTE
CREATE TABLE dbo.aegis_forecast_drift_family_scores (
    family_score_id       BIGINT IDENTITY(1,1) NOT NULL,
    drift_event_id        BIGINT       NOT NULL,
    drift_family          VARCHAR(20)  NOT NULL,
    family_score          DECIMAL(5,2) NULL,                    -- NULL = NOT_COMPUTABLE
    raw_magnitude         DECIMAL(18,6) NULL,
    eligibility_status    VARCHAR(20)  NOT NULL CONSTRAINT DF_fs_elig DEFAULT ('COMPUTED'),
    not_computable_reason VARCHAR(60)  NULL,
    version_count         INT          NULL,
    horizon_point_count   INT          NULL,
    -- shape
    shape_distance        DECIMAL(9,4) NULL,
    divergence_start_date DATE         NULL,
    max_curve_delta       DECIMAL(18,6) NULL,
    max_curve_delta_pct   DECIMAL(9,4) NULL,
    -- stability
    value_delta           DECIMAL(18,6) NULL,
    value_delta_pct       DECIMAL(9,4) NULL,
    cumulative_revision_pct DECIMAL(9,4) NULL,
    structural_break_flag BIT          NULL,
    -- volatility
    rolling_stddev        DECIMAL(18,6) NULL,
    rolling_cov           DECIMAL(9,4) NULL,
    rolling_mad           DECIMAL(9,4) NULL,
    oscillation_count     INT          NULL,
    sign_change_freq      DECIMAL(5,4) NULL,
    volatility_class      VARCHAR(20)  NULL,
    created_at            DATETIME2(3) NOT NULL CONSTRAINT DF_fs_ca DEFAULT (SYSUTCDATETIME()),
    CONSTRAINT PK_aegis_forecast_drift_family_scores PRIMARY KEY (family_score_id),
    CONSTRAINT UQ_family_scores UNIQUE (drift_event_id, drift_family),
    CONSTRAINT CK_fs_score CHECK (family_score IS NULL OR family_score BETWEEN 0 AND 100),
    CONSTRAINT CK_fs_family CHECK (drift_family IN ('performance','shape','stability','volatility')),
    CONSTRAINT CK_fs_elig CHECK (eligibility_status IN ('COMPUTED','NOT_COMPUTABLE')),
    CONSTRAINT FK_family_signal FOREIGN KEY (drift_event_id) REFERENCES dbo.aegis_forecast_drift_signals (drift_event_id)
);

-- ############################################################################
-- 5) EVENT HISTORY (append-only lifecycle)
-- ############################################################################
-- DESIGN ONLY — DO NOT EXECUTE
CREATE TABLE dbo.aegis_forecast_drift_event_history (
    event_history_id BIGINT IDENTITY(1,1) NOT NULL,
    drift_event_id   BIGINT       NOT NULL,
    old_status       VARCHAR(20)  NULL,
    new_status       VARCHAR(20)  NOT NULL,
    changed_at       DATETIME2(3) NOT NULL CONSTRAINT DF_h_ca DEFAULT (SYSUTCDATETIME()),
    changed_by       VARCHAR(100) NOT NULL,
    note             VARCHAR(500) NULL,
    CONSTRAINT PK_aegis_forecast_drift_event_history PRIMARY KEY (event_history_id),
    CONSTRAINT CK_h_status CHECK (new_status IN ('Open','Acknowledged','Investigating','Resolved','Suppressed')),
    CONSTRAINT FK_history_signal FOREIGN KEY (drift_event_id) REFERENCES dbo.aegis_forecast_drift_signals (drift_event_id)
);

-- ############################################################################
-- 6) INDEXES (MVP)  — DESIGN ONLY — DO NOT EXECUTE
-- ############################################################################
CREATE NONCLUSTERED INDEX IX_signals_scenario_key_version ON dbo.aegis_forecast_drift_signals (scenario, forecast_key, forecast_version) INCLUDE (forecast_drift_score, drift_status, severity, drift_type);
CREATE NONCLUSTERED INDEX IX_signals_detected_on ON dbo.aegis_forecast_drift_signals (detected_on DESC) INCLUDE (scenario, forecast_key, drift_type, severity, forecast_drift_score);
CREATE NONCLUSTERED INDEX IX_signals_type_severity ON dbo.aegis_forecast_drift_signals (drift_type, severity, detected_on) INCLUDE (forecast_key, scenario, forecast_drift_score);
CREATE NONCLUSTERED INDEX IX_signals_critical_current ON dbo.aegis_forecast_drift_signals (detected_on DESC) INCLUDE (scenario, forecast_key, drift_type) WHERE severity = 'Critical' AND is_current = 1;
CREATE NONCLUSTERED INDEX IX_signals_events_only ON dbo.aegis_forecast_drift_signals (detected_on DESC) INCLUDE (scenario, forecast_key, drift_type, severity, event_status) WHERE is_event = 1;
CREATE NONCLUSTERED INDEX IX_signals_key_target ON dbo.aegis_forecast_drift_signals (forecast_key, target_date) INCLUDE (forecast_version, stability_drift_score);
CREATE NONCLUSTERED INDEX IX_family_scores_event ON dbo.aegis_forecast_drift_family_scores (drift_event_id, drift_family) INCLUDE (family_score, eligibility_status);
CREATE NONCLUSTERED INDEX IX_family_scores_family ON dbo.aegis_forecast_drift_family_scores (drift_family, family_score);
CREATE NONCLUSTERED INDEX IX_history_event ON dbo.aegis_forecast_drift_event_history (drift_event_id, changed_at DESC);
-- FUTURE (not MVP): NONCLUSTERED COLUMNSTORE for analytics; PARTITION by detected_on (monthly).

-- ############################################################################
-- 7) VIEWS  — conceptual stubs only, DEFINED IN E4_view_contracts.md — DO NOT EXECUTE
--   vw_aegis_forecast_drift_current, _events, _summary, _family_scores, _timeline
-- ############################################################################

/* END — DESIGN ONLY — DO NOT EXECUTE */
