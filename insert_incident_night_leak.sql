INSERT INTO incident (ts, building_id, apartment_id, severity, incident_type, title, description,
                      source_rule)
SELECT strftime('%Y-%m-%d %H:%M:%S', v.hour_ts),
       v.building_id,
       v.apartment_id,

       -- Расчет приоритета. Чем выше значение относительно порога, тем выше приоритет
       CASE
           -- учитываем буффер 1.15 = 1.5 / 1.3
           WHEN v.consumption > v.m3_p95 * 1.15 THEN 'high'
           ELSE 'medium'
           END AS severity,
       'night_water_anomaly',
       'Ночной расход воды выше нормы',
       'В ночные часы зафиксирован аномальный расход воды; требуется проверка на утечку или незакрытый кран.',
       'night_water_p95'
FROM view_night_leak_detect v
WHERE NOT EXISTS(SELECT 1
                 FROM incident i
                 WHERE i.ts = strftime('%Y-%m-%d %H:%M:%S', v.hour_ts)
                   AND i.apartment_id = v.apartment_id
                   AND i.source_rule = 'night_water_p95')
  AND v.is_leak_detected = 1