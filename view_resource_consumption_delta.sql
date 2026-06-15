-- Потребление ресурсов (электроэнергия, вода) за прошедший час
CREATE VIEW IF NOT EXISTS view_resource_consumption_delta AS
WITH base_cte
         AS ( -- CTE для построения временной таблицы, в которой есть текущее значение (current_value) и предыдущее (prev_value)
        SELECT m.measurement_id, -- Для дальнейших тестов проверки корректности рассчета. Это ID текущего замера (не предыдущего)
               m.ts,
               c.complex_id,
               c.name                                                 AS complex,
               b.building_id,
               b.name                                                 AS building,
               d.apartment_id,
               a.apartment_no,
               mt.code,
               mt.unit,
               m.value_num                                            AS current_value,
               LAG(m.value_num) OVER w                                AS prev_value,
               -- julianday преобразует дату в числовое значение (дни). Если время текущего замера и предыдущего отличаются на 2 часа, то значит счетчик был отключен.
               -- далее будем это учитывать, чтобы избежать аномальных значений в расчете дельты
               (julianday(m.ts) - julianday(LAG(m.ts) OVER w)) * 24.0 AS hours_diff
        FROM measurement m
                 JOIN device d ON d.device_id = m.device_id
                 JOIN building b ON b.building_id = d.building_id
                 JOIN complex c ON c.complex_id = b.complex_id
                 JOIN apartment a ON a.apartment_id = d.apartment_id
                 JOIN metric_type mt ON mt.metric_type_id = m.metric_type_id
        WHERE mt.code IN ('water_cold_m3_total', 'water_hot_m3_total', 'electricity_kwh_total')
        WINDOW w AS (PARTITION BY d.device_id ORDER BY m.ts))
SELECT cte.measurement_id,
       cte.ts,
       cte.complex_id,
       cte.building_id,
       cte.complex,
       cte.building,
       cte.apartment_id,
       cte.apartment_no,
       cte.unit,
       cte.code,
       CASE
           WHEN prev_value IS NULL THEN 'first'
           WHEN current_value < prev_value THEN 'negative'
           WHEN hours_diff > 2 THEN 'has_skip'
           ELSE 'normal'
           END AS delta_status,
       CAST(
               CASE
                   WHEN prev_value IS NULL THEN NULL
                   WHEN current_value < prev_value THEN NULL
                   WHEN hours_diff > 2 THEN NULL
                   ELSE current_value - prev_value
                   END AS REAL
       )       AS value
FROM base_cte cte