CREATE VIEW IF NOT EXISTS view_automation_efficiency_hourly AS
WITH hourly_device_states AS (
    SELECT
        strftime('%Y-%m-%d %H:00', m.ts) AS hour_ts,
        d.apartment_id,
        a.apartment_no,
        b.building_id,
        b.name AS building,
        c.complex_id,
        c.name AS complex,

        -- Было ли движение в квартире хотя бы раз за час
        MAX(CASE WHEN mt.code = 'motion_detected' AND (m.value_num > 0 OR m.value_bool = 1) THEN 1 ELSE 0 END) AS has_motion,

        -- Режим термостата (берем последний за час)
        MAX(CASE WHEN mt.code = 'thermostat_mode' THEN m.value_text END) AS thermostat_mode,

        -- Была ли включена вентиляция хотя бы раз за час
        MAX(CASE WHEN mt.code = 'ventilation_on' THEN m.value_bool END) AS ventilation_on,

        -- Средний уровень CO2 за час
        AVG(CASE WHEN mt.code = 'co2_ppm' THEN m.value_num END) AS co2_ppm_avg,

        -- Был ли включен свет хотя бы раз за час
        MAX(CASE WHEN mt.code = 'light_on' THEN m.value_bool END) AS light_on

    FROM measurement m
             JOIN device d ON d.device_id = m.device_id
             JOIN apartment a ON a.apartment_id = d.apartment_id
             JOIN building b ON b.building_id = d.building_id
             JOIN complex c ON c.complex_id = b.complex_id
             JOIN metric_type mt ON mt.metric_type_id = m.metric_type_id
    WHERE mt.code IN ('motion_detected', 'thermostat_mode', 'ventilation_on', 'co2_ppm', 'light_on')
      AND m.quality_flag = 'ok'
    GROUP BY strftime('%Y-%m-%d %H:00', m.ts), d.apartment_id, a.apartment_no, b.building_id, b.name, c.complex_id, c.name
),
     automation_flags AS (
         SELECT
             hds.hour_ts,
             hds.complex_id,
             hds.complex,
             hds.building_id,
             hds.building,
             hds.apartment_id,
             hds.apartment_no,

             hds.has_motion AS has_motion,
             hds.thermostat_mode AS thermostat_mode,
             hds.ventilation_on AS ventilation_on,
             hds.co2_ppm_avg,
             hds.light_on AS light_on,
             rp.works_office_hours AS works_office_hours,

             -- Случай 1. CO2 > 1000, но вентиляция не включена
             CASE
                 WHEN hds.co2_ppm_avg > 1000 AND hds.ventilation_on = 0 THEN 1
                 ELSE 0
                 END AS ventilation_missed,

             -- Случай 2. В квартире никого нет, но термостат в режиме "comfort"
             CASE
                 WHEN hds.has_motion = 0 AND hds.thermostat_mode = 'comfort' THEN 1
                 ELSE 0
                 END AS climate_wasteful,

             -- Случай 3. В квартире никого нет, но свет горит
             CASE
                 WHEN hds.has_motion = 0 AND hds.light_on = 1 THEN 1
                 ELSE 0
                 END AS light_wasteful

         FROM hourly_device_states hds
                  LEFT JOIN resident_profile rp ON hds.apartment_id = rp.apartment_id
     )
SELECT
    hour_ts,
    complex_id,
    complex,
    building_id,
    building,
    apartment_id,
    apartment_no,

    has_motion,
    thermostat_mode,
    ventilation_on,
    ROUND(co2_ppm_avg, 0) AS co2_ppm_avg,
    light_on,
    works_office_hours,

    -- Флаги BI
    ventilation_missed,
    climate_wasteful,
    light_wasteful,

    -- Простой процентный индекс эффективности
    -- У нас 3 системы. Каждая работающая оптимально дает 33.3%.
    -- Рассчитываем по формуле (3 - количество сбоев) / 3 * 100
    CAST(ROUND((3.0 - (ventilation_missed + climate_wasteful + light_wasteful)) / 3.0 * 100.0, 0) AS INTEGER) AS automation_efficiency_score,

    -- Статус на основе суммы сбоев (0, 1 или 2+)
    CASE
        WHEN (ventilation_missed + climate_wasteful + light_wasteful) = 0 THEN 'optimal'
        WHEN (ventilation_missed + climate_wasteful + light_wasteful) = 1 THEN 'suboptimal'
        ELSE 'critical'
        END AS automation_status

FROM automation_flags;