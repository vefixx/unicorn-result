-- Сравнение потребления по зданиям (по среднему на квартиру за день)

CREATE VIEW IF NOT EXISTS stat_03_building_resource_avg AS
SELECT
    v.complex_id,
    v.complex,
    v.building_id,
    v.building,
    v.code,
    v.unit,
    ROUND(AVG(v.value_sum), 2) AS avg_daily_consumption_per_apt,
    COUNT(DISTINCT v.apartment_id) AS active_apartments_count
FROM view_resource_consumption_daily v
WHERE v.code IN ('electricity_kwh_total', 'water_cold_m3_total', 'water_hot_m3_total')
  AND v.not_full_day = 0
GROUP BY v.complex_id, v.complex, v.building_id, v.building, v.code, v.unit
ORDER BY v.building_id, v.code;