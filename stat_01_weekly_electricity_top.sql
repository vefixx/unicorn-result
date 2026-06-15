-- Топ квартир по потреблению электроэнергии

CREATE VIEW IF NOT EXISTS stat_01_weekly_electricity_top AS
SELECT
    strftime('%Y-%W', v.day_ts) AS week_number,
    v.complex_id,
    v.complex,
    v.building_id,
    v.building,
    v.apartment_id,
    v.apartment_no,
    SUM(v.value_sum) AS total_kwh_week,
    COUNT(v.day_ts) AS days_recorded
FROM view_resource_consumption_daily v
WHERE v.code = 'electricity_kwh_total'
  AND v.value_sum IS NOT NULL
GROUP BY strftime('%Y-%W', v.day_ts), v.complex_id, v.complex, v.building_id, v.building, v.apartment_id, v.apartment_no
ORDER BY total_kwh_week DESC;