-- Рейтинг квартир по средней эффективности автоматизации
CREATE VIEW IF NOT EXISTS stat_07_building_automation_rating AS
SELECT
    ae.complex_id,
    ae.complex,
    ae.building_id,
    ae.building,
    ROUND(AVG(ae.automation_efficiency_score), 1) AS avg_automation_score,
    COUNT(DISTINCT ae.apartment_id) AS monitored_apartments
FROM view_automation_efficiency_hourly ae
GROUP BY ae.complex_id, ae.complex, ae.building_id, ae.building
ORDER BY avg_automation_score DESC;