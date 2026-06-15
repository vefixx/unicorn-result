CREATE VIEW IF NOT EXISTS view_elevator_risk_score AS
WITH risk_base AS (
    SELECT
        hour_ts,
        building_id,
        building,
        complex,
        hourly_trips,
        max_vibration_rms,
        CASE
            WHEN max_vibration_rms > 4.5 THEN 60
            WHEN max_vibration_rms >= 2.0 THEN 30
            ELSE 0
            END AS vibration_risk_pts,
        CASE
            WHEN hourly_trips > 60 THEN 40
            WHEN hourly_trips >= 30 THEN 20
            ELSE 0
            END AS load_risk_pts
    FROM view_elevator_hourly_stats
),
     risk_calculated AS (
         SELECT
             hour_ts,
             building_id,
             building,
             complex,
             hourly_trips,
             max_vibration_rms,
             vibration_risk_pts,
             load_risk_pts,
             (vibration_risk_pts + load_risk_pts) AS total_risk_score,
             CASE
                 WHEN (vibration_risk_pts + load_risk_pts) >= 80 THEN 'critical'
                 WHEN (vibration_risk_pts + load_risk_pts) >= 50 THEN 'high'
                 WHEN (vibration_risk_pts + load_risk_pts) >= 20 THEN 'medium'
                 ELSE 'low'
                 END AS risk_level
         FROM risk_base
     ),
     predictive_flag AS (
         SELECT
             hour_ts,
             building_id,
             building,
             complex,
             hourly_trips,
             max_vibration_rms,
             vibration_risk_pts,
             load_risk_pts,
             total_risk_score,
             risk_level,
             CASE
                 WHEN total_risk_score >= 50
                     AND LAG(total_risk_score) OVER (PARTITION BY building_id ORDER BY hour_ts) >= 50
                     THEN 1
                 ELSE 0
                 END AS predictive_maintenance_needed
         FROM risk_calculated
     )
SELECT
    hour_ts,
    building_id,
    building,
    complex,
    hourly_trips,
    max_vibration_rms,
    vibration_risk_pts,
    load_risk_pts,
    total_risk_score,
    risk_level,
    predictive_maintenance_needed
FROM predictive_flag;