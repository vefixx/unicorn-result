CREATE VIEW IF NOT EXISTS view_resource_consumption_hourly AS
SELECT
    strftime('%Y-%m-%d %H:00', v.ts) AS hour_ts,
    v.complex_id,
    v.complex,
    v.building_id,
    v.building,
    v.apartment_id,
    v.apartment_no,
    v.unit,
    v.code,
    AVG(v.value) AS value_avg,
    SUM(v.value) AS value_sum,
    MIN(v.value) AS value_min,
    MAX(v.value) AS value_max
FROM view_resource_consumption_delta v
WHERE v.value IS NOT NULL
GROUP BY strftime('%Y-%m-%d %H:00', v.ts), v.complex_id, v.complex, v.building_id, v.building, v.apartment_id, v.apartment_no, v.unit, v.code;