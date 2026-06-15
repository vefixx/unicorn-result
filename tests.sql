
-- ТЕСТ 1: Наличие данных в основных таблицах
SELECT 'TEST 1: DATA EXISTS' AS test_name;

SELECT 'complex' AS table_name,
       COUNT(*) AS row_count,
       CASE WHEN COUNT(*) > 0 THEN 'PASS' ELSE 'FAIL' END AS status
FROM complex
UNION ALL
SELECT 'building', COUNT(*), CASE WHEN COUNT(*) > 0 THEN 'PASS' ELSE 'FAIL' END FROM building
UNION ALL
SELECT 'apartment', COUNT(*), CASE WHEN COUNT(*) > 0 THEN 'PASS' ELSE 'FAIL' END FROM apartment
UNION ALL
SELECT 'device', COUNT(*), CASE WHEN COUNT(*) > 0 THEN 'PASS' ELSE 'FAIL' END FROM device
UNION ALL
SELECT 'measurement', COUNT(*), CASE WHEN COUNT(*) > 0 THEN 'PASS' ELSE 'FAIL' END FROM measurement;

-- ТЕСТ 2: Диапазоны значений
SELECT 'TEST 2: VALUE RANGES' AS test_name;

SELECT 'co2_range' AS test_case,
       COUNT(*) AS invalid_count,
       CASE WHEN COUNT(*) = 0 THEN 'PASS' ELSE 'FAIL' END AS status
FROM view_air_quality_hourly
WHERE co2_ppm_avg < 0 OR co2_ppm_avg > 5000
UNION ALL
SELECT 'temp_range', COUNT(*), CASE WHEN COUNT(*) = 0 THEN 'PASS' ELSE 'FAIL' END
FROM view_air_quality_hourly
WHERE temp_c_avg < -10 OR temp_c_avg > 50
UNION ALL
SELECT 'humidity_range', COUNT(*), CASE WHEN COUNT(*) = 0 THEN 'PASS' ELSE 'FAIL' END
FROM view_air_quality_hourly
WHERE humidity_pct_avg < 0 OR humidity_pct_avg > 100
UNION ALL
SELECT 'iaqi_range', COUNT(*), CASE WHEN COUNT(*) = 0 THEN 'PASS' ELSE 'FAIL' END
FROM view_air_quality_hourly
WHERE iaqi_score < 0 OR iaqi_score > 100
UNION ALL
SELECT 'comfort_score_range', COUNT(*), CASE WHEN COUNT(*) = 0 THEN 'PASS' ELSE 'FAIL' END
FROM view_room_comfort_hourly
WHERE comfort_score < 0 OR comfort_score > 100
UNION ALL
SELECT 'automation_score_range', COUNT(*), CASE WHEN COUNT(*) = 0 THEN 'PASS' ELSE 'FAIL' END
FROM view_automation_efficiency_hourly
WHERE automation_efficiency_score < 0 OR automation_efficiency_score > 100
UNION ALL
SELECT 'elevator_risk_range', COUNT(*), CASE WHEN COUNT(*) = 0 THEN 'PASS' ELSE 'FAIL' END
FROM view_elevator_risk_score
WHERE total_risk_score < 0 OR total_risk_score > 100
UNION ALL
SELECT 'vibration_range', COUNT(*), CASE WHEN COUNT(*) = 0 THEN 'PASS' ELSE 'FAIL' END
FROM view_elevator_hourly_stats
WHERE max_vibration_rms < 0 OR max_vibration_rms > 20;

-- ТЕСТ 3: Отрицательные дельты потребления
SELECT 'TEST 3: NEGATIVE DELTAS' AS test_name;

SELECT 'negative_electricity' AS test_case,
       COUNT(*) AS invalid_count,
       CASE WHEN COUNT(*) = 0 THEN 'PASS' ELSE 'FAIL' END AS status
FROM view_resource_consumption_delta
WHERE code = 'electricity_kwh_total'
  AND value < 0
  AND delta_status = 'normal'
UNION ALL
SELECT 'negative_water_cold',
       COUNT(*),
       CASE WHEN COUNT(*) = 0 THEN 'PASS' ELSE 'FAIL' END
FROM view_resource_consumption_delta
WHERE code = 'water_cold_m3_total'
  AND value < 0
  AND delta_status = 'normal'
UNION ALL
SELECT 'negative_water_hot',
       COUNT(*),
       CASE WHEN COUNT(*) = 0 THEN 'PASS' ELSE 'FAIL' END
FROM view_resource_consumption_delta
WHERE code = 'water_hot_m3_total'
  AND value < 0
  AND delta_status = 'normal';

-- ТЕСТ 4: Полнота часовых данных
SELECT 'TEST 4: HOURLY COMPLETENESS' AS test_name;

SELECT DATE(hour_ts) AS day,
       apartment_id,
       code,
       COUNT(*) AS hours_count,
       CASE
           WHEN COUNT(*) = 24 THEN 'PASS'
           WHEN COUNT(*) >= 20 THEN 'WARNING'
           ELSE 'FAIL'
           END AS status
FROM view_resource_consumption_hourly
WHERE code = 'electricity_kwh_total'
GROUP BY DATE(hour_ts), apartment_id, code
HAVING COUNT(*) < 24
LIMIT 10;

-- ТЕСТ 5: Проверка IAQI расчета
SELECT 'TEST 5: IAQI CALCULATION' AS test_name;

SELECT 'iaqi_not_null' AS test_case,
       COUNT(*) AS null_count,
       CASE WHEN COUNT(*) = 0 THEN 'PASS' ELSE 'FAIL' END AS status
FROM view_air_quality_hourly
WHERE iaqi_score IS NULL
UNION ALL
SELECT 'iaqi_in_range',
       COUNT(*),
       CASE WHEN COUNT(*) = 0 THEN 'PASS' ELSE 'FAIL' END
FROM view_air_quality_hourly
WHERE iaqi_score NOT BETWEEN 0 AND 100;

-- ТЕСТ 6: Проверка risk score для лифтов
SELECT 'TEST 6: ELEVATOR RISK SCORE' AS test_name;

SELECT 'risk_score_not_null' AS test_case,
       COUNT(*) AS null_count,
       CASE WHEN COUNT(*) = 0 THEN 'PASS' ELSE 'FAIL' END AS status
FROM view_elevator_risk_score
WHERE total_risk_score IS NULL
UNION ALL
SELECT 'risk_score_in_range',
       COUNT(*),
       CASE WHEN COUNT(*) = 0 THEN 'PASS' ELSE 'FAIL' END
FROM view_elevator_risk_score
WHERE total_risk_score NOT BETWEEN 0 AND 100
UNION ALL
SELECT 'risk_level_valid',
       COUNT(*),
       CASE WHEN COUNT(*) = 0 THEN 'PASS' ELSE 'FAIL' END
FROM view_elevator_risk_score
WHERE risk_level NOT IN ('low', 'medium', 'high', 'critical');

SELECT 'TEST 9: Проверка журнала инцидентов на дубли' AS test_name;

SELECT 'duplicate_incidents' AS test_case,
       COUNT(*) AS duplicate_count,
       CASE WHEN COUNT(*) = 0 THEN 'PASS' ELSE 'FAIL' END AS status
FROM (
         SELECT ts, apartment_id, source_rule, COUNT(*) AS cnt
         FROM incident
         GROUP BY ts, apartment_id, source_rule
         HAVING COUNT(*) > 1
     );

-- Тесты
SELECT 'Тесты:' AS '';

WITH all_tests AS (
    -- Тест 1: Data Exists
    SELECT 'TEST 1: DATA EXISTS' AS test_suite,
           CASE WHEN COUNT(*) > 0 THEN 'PASS' ELSE 'FAIL' END AS status
    FROM (SELECT 1 FROM complex UNION ALL SELECT 1 FROM building UNION ALL SELECT 1 FROM apartment UNION ALL SELECT 1 FROM device UNION ALL SELECT 1 FROM measurement)

    UNION ALL

    -- Тест 2: Область значений
    SELECT 'TEST 2: VALUE RANGES',
           CASE WHEN COUNT(*) = 0 THEN 'PASS' ELSE 'FAIL' END
    FROM (
             SELECT 1 FROM view_air_quality_hourly WHERE co2_ppm_avg < 0 OR co2_ppm_avg > 5000
             UNION ALL
             SELECT 1 FROM view_air_quality_hourly WHERE temp_c_avg < -10 OR temp_c_avg > 50
             UNION ALL
             SELECT 1 FROM view_air_quality_hourly WHERE humidity_pct_avg < 0 OR humidity_pct_avg > 100
             UNION ALL
             SELECT 1 FROM view_air_quality_hourly WHERE iaqi_score < 0 OR iaqi_score > 100
             UNION ALL
             SELECT 1 FROM view_room_comfort_hourly WHERE comfort_score < 0 OR comfort_score > 100
             UNION ALL
             SELECT 1 FROM view_automation_efficiency_hourly WHERE automation_efficiency_score < 0 OR automation_efficiency_score > 100
             UNION ALL
             SELECT 1 FROM view_elevator_risk_score WHERE total_risk_score < 0 OR total_risk_score > 100
             UNION ALL
             SELECT 1 FROM view_elevator_hourly_stats WHERE max_vibration_rms < 0 OR max_vibration_rms > 20
         )

    UNION ALL

    -- Тест 3: Отрицательные дельты
    SELECT 'TEST 3: NEGATIVE DELTAS',
           CASE WHEN COUNT(*) = 0 THEN 'PASS' ELSE 'FAIL' END
    FROM view_resource_consumption_delta
    WHERE value < 0 AND delta_status = 'normal'

    UNION ALL

    -- Тест 4: Расчет IAQI
    SELECT 'TEST 4: IAQI CALCULATION',
           CASE WHEN COUNT(*) = 0 THEN 'PASS' ELSE 'FAIL' END
    FROM view_air_quality_hourly
    WHERE iaqi_score IS NULL OR iaqi_score NOT BETWEEN 0 AND 100

    UNION ALL

    -- Тест 5: risk score лифтов
    SELECT 'TEST 5: ELEVATOR RISK',
           CASE WHEN COUNT(*) = 0 THEN 'PASS' ELSE 'FAIL' END
    FROM view_elevator_risk_score
    WHERE total_risk_score IS NULL OR total_risk_score NOT BETWEEN 0 AND 100 OR risk_level NOT IN ('low', 'medium', 'high', 'critical')
)
SELECT test_suite,
       status,
       CASE WHEN status = 'PASS' THEN 'good' ELSE 'bad' END AS result
FROM all_tests
ORDER BY test_suite;

SELECT 'Статистика:' AS '';

WITH all_tests AS (
    SELECT CASE WHEN COUNT(*) > 0 THEN 'PASS' ELSE 'FAIL' END AS status
    FROM (SELECT 1 FROM complex UNION ALL SELECT 1 FROM building UNION ALL SELECT 1 FROM apartment UNION ALL SELECT 1 FROM device UNION ALL SELECT 1 FROM measurement)
    UNION ALL
    SELECT CASE WHEN COUNT(*) = 0 THEN 'PASS' ELSE 'FAIL' END
    FROM (SELECT 1 FROM device d LEFT JOIN building b ON d.building_id = b.building_id WHERE b.building_id IS NULL UNION ALL SELECT 1 FROM measurement m LEFT JOIN device d ON m.device_id = d.device_id WHERE d.device_id IS NULL UNION ALL SELECT 1 FROM apartment a LEFT JOIN building b ON a.building_id = b.building_id WHERE b.building_id IS NULL)
    UNION ALL
    SELECT CASE WHEN COUNT(*) = 0 THEN 'PASS' ELSE 'FAIL' END
    FROM (SELECT 1 FROM view_air_quality_hourly WHERE co2_ppm_avg < 0 OR co2_ppm_avg > 5000 UNION ALL SELECT 1 FROM view_air_quality_hourly WHERE temp_c_avg < -10 OR temp_c_avg > 50 UNION ALL SELECT 1 FROM view_air_quality_hourly WHERE humidity_pct_avg < 0 OR humidity_pct_avg > 100 UNION ALL SELECT 1 FROM view_air_quality_hourly WHERE iaqi_score < 0 OR iaqi_score > 100 UNION ALL SELECT 1 FROM view_room_comfort_hourly WHERE comfort_score < 0 OR comfort_score > 100 UNION ALL SELECT 1 FROM view_automation_efficiency_hourly WHERE automation_efficiency_score < 0 OR automation_efficiency_score > 100 UNION ALL SELECT 1 FROM view_elevator_risk_score WHERE total_risk_score < 0 OR total_risk_score > 100 UNION ALL SELECT 1 FROM view_elevator_hourly_stats WHERE max_vibration_rms < 0 OR max_vibration_rms > 20)
    UNION ALL
    SELECT CASE WHEN COUNT(*) = 0 THEN 'PASS' ELSE 'FAIL' END
    FROM view_resource_consumption_delta WHERE value < 0 AND delta_status = 'normal'
    UNION ALL
    SELECT CASE WHEN COUNT(*) = 0 THEN 'PASS' ELSE 'FAIL' END
    FROM view_air_quality_hourly WHERE iaqi_score IS NULL OR iaqi_score NOT BETWEEN 0 AND 100
    UNION ALL
    SELECT CASE WHEN COUNT(*) = 0 THEN 'PASS' ELSE 'FAIL' END
    FROM view_elevator_risk_score WHERE total_risk_score IS NULL OR total_risk_score NOT BETWEEN 0 AND 100 OR risk_level NOT IN ('low', 'medium', 'high', 'critical')
)
SELECT
    COUNT(*) AS total_tests,
    SUM(CASE WHEN status = 'PASS' THEN 1 ELSE 0 END) AS passed,
    SUM(CASE WHEN status = 'FAIL' THEN 1 ELSE 0 END) AS failed,
    ROUND(CAST(SUM(CASE WHEN status = 'PASS' THEN 1 ELSE 0 END) AS REAL) / COUNT(*) * 100, 1) AS pass_percentage
FROM all_tests;

SELECT 'Тесты завершены' AS '';
