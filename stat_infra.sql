CREATE VIEW IF NOT EXISTS stat_infra_01_daily_risk_summary AS
SELECT
    DATE(hour_ts) AS day_ts,
    complex,
    building,
    ROUND(AVG(total_risk_score), 1) AS avg_daily_risk_score,
    MAX(total_risk_score) AS max_daily_risk_score,
    SUM(predictive_maintenance_needed) AS hours_needing_maintenance
FROM view_elevator_risk_score
GROUP BY DATE(hour_ts), complex, building
ORDER BY day_ts DESC, avg_daily_risk_score DESC;

CREATE VIEW IF NOT EXISTS stat_infra_02_peak_load_hours AS
SELECT
    complex,
    CAST(strftime('%H', hour_ts) AS INTEGER) AS hour_of_day,
    ROUND(AVG(hourly_trips), 1) AS avg_trips_per_hour,
    MAX(hourly_trips) AS max_trips_in_hour,
    COUNT(building_id) AS building_samples
FROM view_elevator_hourly_stats
GROUP BY complex, CAST(strftime('%H', hour_ts) AS INTEGER)
ORDER BY complex, avg_trips_per_hour DESC;

CREATE VIEW IF NOT EXISTS stat_infra_03_vibration_anomalies_top AS
SELECT
    complex,
    building,
    COUNT(CASE WHEN max_vibration_rms > 4.5 THEN 1 END) AS critical_vibration_hours,
    COUNT(CASE WHEN max_vibration_rms >= 2.0 AND max_vibration_rms <= 4.5 THEN 1 END) AS warning_vibration_hours,
    ROUND(AVG(max_vibration_rms), 2) AS avg_vibration_rms
FROM view_elevator_hourly_stats
GROUP BY complex, building
ORDER BY critical_vibration_hours DESC, warning_vibration_hours DESC;

CREATE VIEW IF NOT EXISTS stat_infra_04_maintenance_alerts AS
SELECT
    DATE(hour_ts) AS alert_date,
    complex,
    building,
    COUNT(*) AS consecutive_high_risk_hours,
    MAX(total_risk_score) AS peak_risk_score,
    MAX(max_vibration_rms) AS peak_vibration_rms
FROM view_elevator_risk_score
WHERE predictive_maintenance_needed = 1
GROUP BY DATE(hour_ts), complex, building
ORDER BY alert_date DESC, peak_risk_score DESC;