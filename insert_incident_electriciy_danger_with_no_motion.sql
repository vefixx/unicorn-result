INSERT INTO incident (ts, building_id, apartment_id, severity, incident_type, title, description, source_rule)
SELECT strftime('%Y-%m-%d %H:%M:%S', v.hour_ts),
       v.building_id,
       v.apartment_id,

       -- Расчет приоритета. Чем выше значение относительно порога, тем выше приоритет
       CASE
           -- учитываем буффер 1.15 = 1.5 / 1.3
           WHEN v.consumption > v.kwh_p70 * 1.15 THEN 'high'
           ELSE 'medium'
           END AS severity,
       'high_electricity_no_motion',
       'Потребление электроэнергии выше нормы при отсутствии движения',
       'Зафиксировано аномальное потребление электроэнергии при отсутствии движения в квартире',
       'electricity_p70'
FROM view_electricity_danger_with_no_motion_detect v
WHERE NOT EXISTS(SELECT 1
                 FROM incident i
                 WHERE i.ts = strftime('%Y-%m-%d %H:%M:%S', v.hour_ts)
                   AND i.apartment_id = v.apartment_id
                   AND i.source_rule = 'electricity_p70')
  AND v.is_danger = 1