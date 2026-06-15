INSERT OR REPLACE INTO electricity_profile (apartment_id, apartment_no, code, hour_of_day, kwh_p70, rows_used)
WITH rank_cte AS (SELECT v.apartment_id,
                         v.apartment_no,
                         v.code,
                         CAST(strftime('%H', v.hour_ts) AS INTEGER) AS hour_of_day,
                         v.value_sum,
                         PERCENT_RANK() OVER (
                             PARTITION BY v.apartment_id, v.code, CAST(strftime('%H', v.hour_ts) AS INTEGER)
                             ORDER BY v.value_sum)                  AS pct_rank
                  FROM view_resource_consumption_hourly v
                  WHERE v.code = 'electricity_kwh_total'
                    AND v.value_sum IS NOT NULL),
     -- исключим все замеры, позиция которых больше 70%
     p70_cte AS (SELECT apartment_id,
                        apartment_no,
                        code,
                        hour_of_day,
                        MAX(value_sum) AS p70,
                        COUNT(*)       AS rows_used
                 FROM rank_cte
                 WHERE pct_rank <= 0.7
                 GROUP BY apartment_id, apartment_no, code, hour_of_day)
SELECT apartment_id,
       apartment_no,
       code,
       hour_of_day,
       -- умножение на 1.3 является буфером для значений
       p70 * 1.3,
       rows_used
FROM p70_cte