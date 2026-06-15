CREATE VIEW IF NOT EXISTS view_night_stats_p95 AS
WITH rank_cte AS (SELECT v.apartment_id,
                         v.apartment_no,
                         v.code,
                         v.unit,
                         CAST(strftime('%H', v.hour_ts) AS INTEGER) AS hour_of_day,
                         v.value_sum,
                         PERCENT_RANK() OVER (
                             PARTITION BY v.apartment_id, v.code, CAST(strftime('%H', v.hour_ts) AS INTEGER)
                             ORDER BY v.value_sum)                  AS pct_rank
                  FROM view_resource_consumption_hourly v
                  WHERE code IN ('water_cold_m3_total', 'water_hot_m3_total')
                    AND v.value_sum IS NOT NULL),
     p95_cte AS (
         -- берем все строки, где pct_rank <= 0.95 и находим максимум
         SELECT apartment_id,
                apartment_no,
                code,
                unit,
                hour_of_day,
                MAX(value_sum) AS p95,
                COUNT(*)       AS rows_used
         FROM rank_cte
         WHERE pct_rank <= 0.95
         GROUP BY apartment_id, apartment_no, code, unit, hour_of_day)
SELECT apartment_id,
       apartment_no,
       code,
       unit,
       hour_of_day,
       -- умножение на 1.1 является буфером для значений
       p95 * 1.1 AS p95,
       rows_used
FROM p95_cte