CREATE VIEW IF NOT EXISTS view_elevator_hourly_stats AS
WITH base_measurements AS (
    SELECT
        strftime('%Y-%m-%d %H:00', m.ts) AS hour_ts,
        d.building_id,
        b.name AS building,
        c.name AS complex,
        mt.code,
        m.value_num,
        m.ts AS raw_ts
    FROM measurement m
             JOIN device d ON m.device_id = d.device_id
             JOIN building b ON d.building_id = b.building_id
             JOIN complex c ON b.complex_id = c.complex_id
             JOIN metric_type mt ON m.metric_type_id = mt.metric_type_id
    WHERE mt.code IN ('elevator_trips_total', 'elevator_vibration_rms')
      AND m.quality_flag = 'ok'
),
     all_hours_buildings AS (
         SELECT DISTINCT
             hour_ts,
             building_id,
             MAX(building) AS building,
             MAX(complex) AS complex
         FROM base_measurements
         GROUP BY hour_ts, building_id
     ),
     trip_deltas AS (
         SELECT
             hour_ts,
             building_id,
             SUM(value_num) AS current_trips_sum,
             LAG(SUM(value_num)) OVER (PARTITION BY building_id ORDER BY hour_ts) AS prev_trips,
             (julianday(hour_ts) - julianday(LAG(hour_ts) OVER (PARTITION BY building_id ORDER BY hour_ts))) * 24.0 AS hours_diff
         FROM base_measurements
         WHERE code = 'elevator_trips_total'
         GROUP BY hour_ts, building_id
     ),
     clean_trips AS (
         SELECT
             hour_ts,
             building_id,
             CASE
                 WHEN prev_trips IS NULL
                     OR current_trips_sum < prev_trips
                     OR hours_diff > 2
                     THEN 0
                 ELSE current_trips_sum - prev_trips
                 END AS hourly_trips
         FROM trip_deltas
     ),
     vibration_agg AS (
         SELECT
             hour_ts,
             building_id,
             MAX(value_num) AS max_vibration_rms
         FROM base_measurements
         WHERE code = 'elevator_vibration_rms'
         GROUP BY hour_ts, building_id
     )
SELECT
    ah.hour_ts,
    ah.building_id,
    ah.building,
    ah.complex,
    COALESCE(ct.hourly_trips, 0) AS hourly_trips,
    ROUND(COALESCE(va.max_vibration_rms, 0.0), 2) AS max_vibration_rms
FROM all_hours_buildings ah
         LEFT JOIN clean_trips ct
                   ON ah.hour_ts = ct.hour_ts AND ah.building_id = ct.building_id
         LEFT JOIN vibration_agg va
                   ON ah.hour_ts = va.hour_ts AND ah.building_id = va.building_id;