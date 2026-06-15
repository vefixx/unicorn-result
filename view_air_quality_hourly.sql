CREATE VIEW IF NOT EXISTS view_air_quality_hourly AS
WITH hourly_air_metrics AS (
    -- Агрегация всех метрик, относящиеся к качеству воздуха, по всем квартирам и часам
    SELECT strftime('%Y-%m-%d %H:00', m.ts)                                AS hour_ts,
           d.apartment_id,
           a.apartment_no,
           b.building_id,
           b.name                                                          AS building,
           c.complex_id,
           c.name                                                          AS complex,
           AVG(CASE WHEN mt.code = 'room_temp_c' THEN m.value_num END)     AS temp_c_avg,
           AVG(CASE WHEN mt.code = 'humidity_pct' THEN m.value_num END)    AS humidity_pct_avg,
           AVG(CASE WHEN mt.code = 'co2_ppm' THEN m.value_num END)         AS co2_ppm_avg,
           AVG(CASE WHEN mt.code = 'pm25_ug_m3' THEN m.value_num END)      AS pm25_ug_m3_avg,
           AVG(CASE WHEN mt.code = 'voc_index' THEN m.value_num END)       AS voc_index_avg,
           MAX(CASE WHEN mt.code = 'ventilation_on' THEN m.value_bool END) AS ventilation_was_on,
           COUNT(DISTINCT mt.code)                                         AS metrics_count
    FROM measurement m
             JOIN device d ON d.device_id = m.device_id
             JOIN apartment a ON a.apartment_id = d.apartment_id
             JOIN building b ON b.building_id = d.building_id
             JOIN complex c ON c.complex_id = b.complex_id
             JOIN metric_type mt ON mt.metric_type_id = m.metric_type_id
    WHERE mt.code IN ('room_temp_c', 'humidity_pct', 'co2_ppm', 'pm25_ug_m3', 'voc_index', 'ventilation_on')
      AND m.quality_flag = 'ok'
    GROUP BY strftime('%Y-%m-%d %H:00', m.ts), d.apartment_id, a.apartment_no, b.building_id, b.name, c.complex_id,
             c.name),
     -- Расчет IAQI для каждой метрики по формуле IAQI = iaqi_low + (iaqi_high - iaqi_low) * (conc - conc_low) / (conc_high - conc_low)
     iaqi_indexes AS (SELECT am.hour_ts,
                             am.apartment_id,
                             am.apartment_no,
                             am.building_id,
                             am.building,
                             am.complex_id,
                             am.complex,
                             am.temp_c_avg,
                             am.humidity_pct_avg,
                             am.co2_ppm_avg,
                             am.pm25_ug_m3_avg,
                             am.voc_index_avg,
                             am.ventilation_was_on,
                             am.metrics_count,
                             -- CO2
                             CASE
                                 WHEN am.co2_ppm_avg IS NULL THEN NULL
                                 ELSE (SELECT CAST(
                                                      d.iaqi_low + (d.iaqi_high - d.iaqi_low) *
                                                                   (CASE
                                                                        WHEN am.co2_ppm_avg <= d.conc_low THEN 0
                                                                        WHEN am.co2_ppm_avg >= d.conc_high THEN 1
                                                                        ELSE (am.co2_ppm_avg - d.conc_low) / (d.conc_high - d.conc_low)
                                                                       END) AS INTEGER)
                                       FROM aqi_data d
                                       WHERE d.pollutant_code = 'co2_ppm'
                                         AND am.co2_ppm_avg >= d.conc_low
                                         AND (am.co2_ppm_avg < d.conc_high OR d.conc_high IS NULL)
                                       LIMIT 1)
                                 END AS iaqi_co2,

                             -- PM2.5
                             CASE
                                 WHEN am.pm25_ug_m3_avg IS NULL THEN NULL
                                 ELSE (SELECT CAST(
                                                      d.iaqi_low + (d.iaqi_high - d.iaqi_low) *
                                                                   (CASE
                                                                        WHEN am.pm25_ug_m3_avg <= d.conc_low THEN 0
                                                                        WHEN am.pm25_ug_m3_avg >= d.conc_high THEN 1
                                                                        ELSE (am.pm25_ug_m3_avg - d.conc_low) / (d.conc_high - d.conc_low)
                                                                       END) AS INTEGER)
                                       FROM aqi_data d
                                       WHERE d.pollutant_code = 'pm25_ug_m3'
                                         AND am.pm25_ug_m3_avg >= d.conc_low
                                         AND (am.pm25_ug_m3_avg < d.conc_high OR d.conc_high IS NULL)
                                       LIMIT 1)
                                 END AS iaqi_pm25,

                             -- VOC
                             CASE
                                 WHEN am.voc_index_avg IS NULL THEN NULL
                                 ELSE (SELECT CAST(
                                                      d.iaqi_low + (d.iaqi_high - d.iaqi_low) *
                                                                   (CASE
                                                                        WHEN am.voc_index_avg <= d.conc_low THEN 0
                                                                        WHEN am.voc_index_avg >= d.conc_high THEN 1
                                                                        ELSE (am.voc_index_avg - d.conc_low) / (d.conc_high - d.conc_low)
                                                                       END) AS INTEGER)
                                       FROM aqi_data d
                                       WHERE d.pollutant_code = 'voc_index'
                                         AND am.voc_index_avg >= d.conc_low
                                         AND (am.voc_index_avg < d.conc_high OR d.conc_high IS NULL)
                                       LIMIT 1)
                                 END AS iaqi_voc,

                             -- Для температуры
                             CASE
                                 WHEN am.temp_c_avg IS NULL THEN NULL
                                 ELSE (SELECT CAST(
                                                      d.iaqi_low + (d.iaqi_high - d.iaqi_low) *
                                                                   (CASE
                                                                        WHEN am.temp_c_avg <= d.conc_low THEN 0
                                                                        WHEN am.temp_c_avg >= d.conc_high THEN 1
                                                                        ELSE (am.temp_c_avg - d.conc_low) / (d.conc_high - d.conc_low)
                                                                       END) AS INTEGER)
                                       FROM aqi_data d
                                       WHERE d.pollutant_code = 'room_temp_c'
                                         AND am.temp_c_avg >= d.conc_low
                                         AND (am.temp_c_avg < d.conc_high OR d.conc_high IS NULL)
                                       LIMIT 1)
                                 END AS iaqi_temp,

                             -- Для влажности
                             CASE
                                 WHEN am.humidity_pct_avg IS NULL THEN NULL
                                 ELSE (SELECT CAST(
                                                      d.iaqi_low + (d.iaqi_high - d.iaqi_low) *
                                                                   (CASE
                                                                        WHEN am.humidity_pct_avg <= d.conc_low THEN 0
                                                                        WHEN am.humidity_pct_avg >= d.conc_high THEN 1
                                                                        ELSE (am.humidity_pct_avg - d.conc_low) / (d.conc_high - d.conc_low)
                                                                       END) AS INTEGER)
                                       FROM aqi_data d
                                       WHERE d.pollutant_code = 'humidity_pct'
                                         AND am.humidity_pct_avg >= d.conc_low
                                         AND (am.humidity_pct_avg < d.conc_high OR d.conc_high IS NULL)
                                       LIMIT 1)
                                 END AS iaqi_humidity

                      FROM hourly_air_metrics am)
SELECT hour_ts,
       complex_id,
       complex,
       building_id,
       building,
       apartment_id,
       apartment_no,

       ROUND(temp_c_avg, 1)                                                        AS temp_c_avg,
       ROUND(humidity_pct_avg, 1)                                                  AS humidity_pct_avg,
       ROUND(co2_ppm_avg, 0)                                                       AS co2_ppm_avg,
       ROUND(pm25_ug_m3_avg, 1)                                                    AS pm25_ug_m3_avg,
       ROUND(voc_index_avg, 0)                                                     AS voc_index_avg,

       COALESCE(ventilation_was_on, 0)                                             AS ventilation_was_on,


       iaqi_co2,
       iaqi_pm25,
       iaqi_voc,
       iaqi_temp,
       iaqi_humidity,

       -- Рассчитываем финальный IAQI как минимум из всех
       MIN(MIN(iaqi_co2, iaqi_pm25), MIN(MIN(iaqi_voc, iaqi_temp), iaqi_humidity)) AS iaqi_score,

       CASE
           WHEN MIN(MIN(iaqi_co2, iaqi_pm25), MIN(MIN(iaqi_voc, iaqi_temp), iaqi_humidity)) >= 81
               THEN 'good'
           WHEN MIN(MIN(iaqi_co2, iaqi_pm25), MIN(MIN(iaqi_voc, iaqi_temp), iaqi_humidity)) >= 61
               THEN 'moderate'
           WHEN MIN(MIN(iaqi_co2, iaqi_pm25), MIN(MIN(iaqi_voc, iaqi_temp), iaqi_humidity)) >= 41
               THEN 'polluted'
           WHEN MIN(MIN(iaqi_co2, iaqi_pm25), MIN(MIN(iaqi_voc, iaqi_temp), iaqi_humidity)) >= 21
               THEN 'very_polluted'
           ELSE 'severely_polluted'
           END                                                                     AS iaqi_category,

       -- Неэффективность вентиляции. Вентиляции неэффективна, если итоговый IAQI меньше 61 и при этом она была выключена.
       CASE
           WHEN MIN(MIN(iaqi_co2, iaqi_pm25, MIN(MIN(iaqi_voc, iaqi_temp), iaqi_humidity)), 0) < 61
               AND ventilation_was_on = 0 THEN 1
           ELSE 0
           END                                                                     AS ventilation_inefficient

FROM iaqi_indexes;