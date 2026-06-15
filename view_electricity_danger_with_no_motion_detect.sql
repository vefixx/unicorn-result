CREATE VIEW IF NOT EXISTS view_electricity_danger_with_no_motion_detect AS
-- Выявляем наличие движения из measurement
WITH motion_hourly_cte AS (SELECT strftime('%Y-%m-%d %H:00', m.ts)                 AS hour_ts,
                                  d.apartment_id,
                                  CASE WHEN COUNT(*) > 0 THEN 1 ELSE 0 END         AS has_motion_data,
                                  MAX(CASE WHEN m.value_num > 0 THEN 1 ELSE 0 END) AS motion_detect
                           FROM measurement m
                                    JOIN device d ON m.device_id = d.device_id
                                    JOIN metric_type mt ON m.metric_type_id = mt.metric_type_id
                           WHERE mt.code = 'motion_detected'
                           GROUP BY strftime('%Y-%m-%d %H:00', m.ts), d.apartment_id),
     -- Сопоставляем замеры с p70
     elect_with_p70_cte AS (SELECT v.hour_ts,
                                   v.complex_id,
                                   v.complex,
                                   v.building_id,
                                   v.building,
                                   v.apartment_id,
                                   v.apartment_no,
                                   v.value_sum AS consumption,
                                   s.kwh_p70
                            FROM view_resource_consumption_hourly v
                                     JOIN electricity_profile s
                                          ON v.apartment_id = s.apartment_id AND v.code = s.code
                                              AND CAST(strftime('%H', v.hour_ts) AS INTEGER) = s.hour_of_day
                            WHERE v.code = 'electricity_kwh_total'
                              AND v.value_sum IS NOT NULL)
SELECT e.hour_ts,
       e.complex_id,
       e.complex,
       e.building_id,
       e.building,
       e.apartment_id,
       e.apartment_no,
       e.consumption,
       e.kwh_p70,
       m.has_motion_data,
       m.motion_detect,

       -- если текущее значение выше порога + есть данные о движении за этот час + в квартире нет движения, то
       -- is_danger = 1
       CASE
           WHEN e.consumption > e.kwh_p70 AND m.has_motion_data = 1 AND m.motion_detect = 0 THEN 1
           ELSE 0
           END AS is_danger
FROM elect_with_p70_cte e
         JOIN motion_hourly_cte m ON e.apartment_id = m.apartment_id
    AND e.hour_ts = m.hour_ts;