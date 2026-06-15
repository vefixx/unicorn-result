CREATE VIEW IF NOT EXISTS view_room_comfort_hourly AS
WITH hourly_motion AS (
    -- Выявляем факт движения в квартире за час
    SELECT strftime('%Y-%m-%d %H:00', m.ts)                                     AS hour_ts,
           d.apartment_id,
           MAX(CASE WHEN m.value_num > 0 OR m.value_bool = 1 THEN 1 ELSE 0 END) AS has_motion
    FROM measurement m
             JOIN device d ON d.device_id = m.device_id
             JOIN metric_type mt ON mt.metric_type_id = m.metric_type_id
    WHERE mt.code = 'motion_detected'
      AND m.quality_flag = 'ok'
    GROUP BY strftime('%Y-%m-%d %H:00', m.ts), d.apartment_id
),
     hourly_thermostat AS (
         -- Проверяем, был ли термостат в режиме "comfort" хотя бы раз за час
         SELECT strftime('%Y-%m-%d %H:00', m.ts)                          AS hour_ts,
                d.apartment_id,
                MAX(CASE WHEN m.value_text = 'comfort' THEN 1 ELSE 0 END) AS is_comfort_mode
         FROM measurement m
                  JOIN device d ON d.device_id = m.device_id
                  JOIN metric_type mt ON mt.metric_type_id = m.metric_type_id
         WHERE mt.code = 'thermostat_mode'
           AND m.quality_flag = 'ok'
         GROUP BY strftime('%Y-%m-%d %H:00', m.ts), d.apartment_id
     ),
     comfort_base AS (
         -- Соединим качество воздуха, движение, климат и профиль резидента
         SELECT aq.hour_ts,
                aq.complex_id,
                aq.complex,
                aq.building_id,
                aq.building,
                aq.apartment_id,
                aq.apartment_no,
                aq.temp_c_avg,
                aq.humidity_pct_avg,
                aq.co2_ppm_avg,
                aq.iaqi_score,
                aq.ventilation_inefficient,
                m.has_motion,
                t.is_comfort_mode,
                rp.wakeup_hour,
                rp.sleep_hour,
                rp.works_office_hours,
                rp.has_children,
                CAST(strftime('%H', aq.hour_ts) AS INTEGER) AS hour_of_day
         FROM view_air_quality_hourly aq
                  LEFT JOIN hourly_motion m
                            ON aq.apartment_id = m.apartment_id AND aq.hour_ts = m.hour_ts
                  LEFT JOIN hourly_thermostat t
                            ON aq.apartment_id = t.apartment_id AND aq.hour_ts = t.hour_ts
                  LEFT JOIN resident_profile rp
                            ON aq.apartment_id = rp.apartment_id
     ),
     comfort_flags AS (
         SELECT cb.hour_ts,
                cb.complex_id,
                cb.complex,
                cb.building_id,
                cb.building,
                cb.apartment_id,
                cb.apartment_no,
                cb.temp_c_avg,
                cb.humidity_pct_avg,
                cb.co2_ppm_avg,
                cb.iaqi_score,
                cb.ventilation_inefficient,
                cb.has_motion,
                cb.is_comfort_mode,
                cb.wakeup_hour,
                cb.sleep_hour,
                cb.works_office_hours,
                cb.has_children,
                cb.hour_of_day,

                -- Определение времени сна. Проверяем, попадает ли текущее время в профиль сна
                CASE
                    WHEN cb.sleep_hour > cb.wakeup_hour
                        THEN (cb.hour_of_day >= cb.sleep_hour OR cb.hour_of_day < cb.wakeup_hour)
                    ELSE (cb.hour_of_day >= cb.sleep_hour AND cb.hour_of_day < cb.wakeup_hour)
                    END AS is_sleep_time,

                -- Определяем дискомфорт во время сна. Будет 1, если хоть одно из условий сработает:
                -- слишком жарко, слишком холодно или CO2 слишком высокий
                CASE
                    WHEN (CASE
                              WHEN cb.sleep_hour > cb.wakeup_hour
                                  THEN (cb.hour_of_day >= cb.sleep_hour OR cb.hour_of_day < cb.wakeup_hour)
                              ELSE (cb.hour_of_day >= cb.sleep_hour AND cb.hour_of_day < cb.wakeup_hour) END) = 1
                        AND (cb.temp_c_avg > 25.0 OR cb.temp_c_avg < 18.0 OR cb.co2_ppm_avg > 1200)
                        THEN 1
                    ELSE 0
                    END AS is_sleep_discomfort,

                -- Дискомфорт во время бодрствования. Будет 1, если сработает хоть одно из условий:
                -- жарко, прохладно или плохое общее качество воздуха
                CASE
                    WHEN (CASE
                              WHEN cb.sleep_hour > cb.wakeup_hour
                                  THEN (cb.hour_of_day >= cb.sleep_hour OR cb.hour_of_day < cb.wakeup_hour)
                              ELSE (cb.hour_of_day >= cb.sleep_hour AND cb.hour_of_day < cb.wakeup_hour) END) = 0
                        AND (cb.temp_c_avg > 26.0 OR cb.temp_c_avg < 20.0 OR cb.iaqi_score < 60)
                        THEN 1
                    ELSE 0
                    END AS is_active_discomfort,

                -- Проверяем, что термостат в режиме "comfort", но движения нет
                CASE
                    WHEN cb.is_comfort_mode = 1 AND cb.has_motion = 0 THEN 1
                    ELSE 0
                    END AS climate_presence_mismatch
         FROM comfort_base cb
         WHERE cb.iaqi_score IS NOT NULL
     )
SELECT hour_ts,
       complex_id,
       complex,
       building_id,
       building,
       apartment_id,
       apartment_no,

       ROUND(temp_c_avg, 1)       AS temp_c_avg,
       ROUND(humidity_pct_avg, 1) AS humidity_pct_avg,
       ROUND(co2_ppm_avg, 0)      AS co2_ppm_avg,
       iaqi_score,

       has_motion,
       is_comfort_mode,
       is_sleep_time,

       is_sleep_discomfort,
       is_active_discomfort,
       climate_presence_mismatch,
       ventilation_inefficient,

       -- 4 проверяемых фактора. Каждый фактор дает 25%.
       -- Рассчитываем по фомруле (4 - сумма сработавших флагов) / 4 * 100
       CAST(ROUND((4.0 - (is_sleep_discomfort + is_active_discomfort + climate_presence_mismatch + ventilation_inefficient)) / 4.0 * 100.0, 0) AS INTEGER) AS comfort_score,

       CASE
           WHEN (is_sleep_discomfort + is_active_discomfort + climate_presence_mismatch + ventilation_inefficient) = 0 THEN 'good'
           WHEN (is_sleep_discomfort + is_active_discomfort + climate_presence_mismatch + ventilation_inefficient) = 1 THEN 'acceptable'
           WHEN (is_sleep_discomfort + is_active_discomfort + climate_presence_mismatch + ventilation_inefficient) = 2 THEN 'warning'
           ELSE 'critical'
           END AS comfort_category

FROM comfort_flags;