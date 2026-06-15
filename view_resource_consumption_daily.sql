CREATE VIEW IF NOT EXISTS view_resource_consumption_daily AS
SELECT DATE(v.hour_ts)            AS day_ts,
       v.complex_id,
       v.complex,
       v.building_id,
       v.building,
       v.apartment_id,
       v.apartment_no,
       v.unit,
       v.code,
       AVG(v.value_avg) AS value_avg,
       SUM(v.value_sum) AS value_sum,
       MIN(v.value_min) AS value_min,
       MAX(v.value_max) AS value_max,
       COUNT(*)                   AS count,
       -- если 1, то значит за день были обнаружены сбои в замерах
       CASE WHEN COUNT(*) < 24 THEN 1 ELSE 0 END AS not_full_day
FROM view_resource_consumption_hourly v
GROUP BY DATE(v.hour_ts), v.complex_id, v.complex, v.building_id, v.building, v.apartment_id, v.apartment_no, v.unit, v.code