-- Рейтинг квартир по среднему качеству воздуха IAQI за неделю

CREATE VIEW IF NOT EXISTS stat_04_weekly_iaqi_rating AS
SELECT
    strftime('%Y-%W', aq.hour_ts) AS week_number,
    aq.complex_id,
    aq.complex,
    aq.building_id,
    aq.building,
    aq.apartment_id,
    aq.apartment_no,
    ROUND(AVG(aq.iaqi_score), 1) AS avg_iaqi_score,
    ROUND(AVG(aq.co2_ppm_avg), 0) AS avg_co2_ppm
FROM view_air_quality_hourly aq
GROUP BY strftime('%Y-%W', aq.hour_ts), aq.complex_id, aq.complex, aq.building_id, aq.building, aq.apartment_id, aq.apartment_no
ORDER BY avg_iaqi_score DESC;