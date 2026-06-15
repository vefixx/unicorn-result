-- Рейтинг зданий по частоте инцидентов

CREATE VIEW IF NOT EXISTS stat_10_incident_hotspots AS
SELECT
    c.complex_id,
    c.name AS complex,
    b.building_id,
    b.name AS building,
    COUNT(i.incident_id) AS total_incidents,
    SUM(CASE WHEN i.severity = 'high' THEN 1 ELSE 0 END) AS high_severity_count,
    SUM(CASE WHEN i.severity = 'medium' THEN 1 ELSE 0 END) AS medium_severity_count
FROM complex c
         JOIN building b ON b.complex_id = c.complex_id
         LEFT JOIN incident i ON i.building_id = b.building_id
GROUP BY c.complex_id, c.name, b.building_id, b.name
ORDER BY total_incidents DESC;