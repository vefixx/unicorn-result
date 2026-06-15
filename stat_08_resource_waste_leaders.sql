-- Топ квартир по количеству случаев нецелевого использования ресурсов (свет и климат)

CREATE VIEW IF NOT EXISTS stat_08_resource_waste_leaders AS
SELECT
    ae.complex_id,
    ae.complex,
    ae.building_id,
    ae.building,
    ae.apartment_id,
    ae.apartment_no,
    SUM(ae.climate_wasteful) AS climate_waste_hours,
    SUM(ae.light_wasteful) AS light_waste_hours,
    (SUM(ae.climate_wasteful) + SUM(ae.light_wasteful)) AS total_waste_hours
FROM view_automation_efficiency_hourly ae
GROUP BY ae.complex_id, ae.complex, ae.building_id, ae.building, ae.apartment_id, ae.apartment_no
ORDER BY total_waste_hours DESC;