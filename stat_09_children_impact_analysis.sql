-- Влияние состава семьи (а именно наличие детей) на комфорт и потребление

CREATE VIEW IF NOT EXISTS stat_09_children_impact_analysis AS
SELECT
    rp.has_children,
    COUNT(DISTINCT rp.apartment_id) AS apartments_count,
    ROUND(AVG(rc.comfort_score), 1) AS avg_comfort_score,
    ROUND(AVG(rc.iaqi_score), 1) AS avg_iaqi_score,
    ROUND(AVG(elec.total_kwh_week) / 7.0, 2) AS avg_daily_kwh -- Дневное потребление
FROM resident_profile rp
         LEFT JOIN (
    SELECT apartment_id, AVG(comfort_score) AS comfort_score, AVG(iaqi_score) AS iaqi_score
    FROM view_room_comfort_hourly
    GROUP BY apartment_id
) rc ON rp.apartment_id = rc.apartment_id
         LEFT JOIN (
    SELECT apartment_id, SUM(value_sum) AS total_kwh_week
    FROM view_resource_consumption_daily
    WHERE code = 'electricity_kwh_total'
    GROUP BY apartment_id
) elec ON rp.apartment_id = elec.apartment_id
GROUP BY rp.has_children;