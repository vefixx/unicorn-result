-- проблема: мы считаем протечки по каждому типу метрики (code). Чтобы обобщить аномалию до квартиры, то проверим следующее:
-- если хотя бы один тип воды имеет протечку, значит протечка есть по все квартире

CREATE VIEW IF NOT EXISTS view_night_leak_detect AS
WITH source_cte AS (SELECT v.hour_ts,
                           v.complex_id,
                           v.complex,
                           v.building_id,
                           v.building,
                           v.apartment_id,
                           v.apartment_no,
                           v.code,
                           s.m3_p95,
                           CASE WHEN v.value_sum > s.m3_p95 THEN 1 ELSE 0 END AS is_leak_detected
                    FROM view_resource_consumption_hourly v
                             JOIN night_water_profile s
                                  ON s.apartment_id = v.apartment_id
                                      AND v.code = s.code
                                      AND CAST(strftime('%H', v.hour_ts) AS INTEGER) = s.hour_of_day
                    WHERE CAST(strftime('%H', v.hour_ts) AS INTEGER) BETWEEN 2 AND 5
                      AND v.code IN ('water_cold_m3_total', 'water_hot_m3_total')
                      AND v.value_sum IS NOT NULL)
SELECT hour_ts,
       complex_id,
       complex,
       building_id,
       building,
       apartment_id,
       apartment_no,
       MAX(is_leak_detected) AS is_leak_detected
FROM source_cte
GROUP BY hour_ts, complex_id, complex, building_id, building, apartment_id, apartment_no;