-- Топ квартир с наибольшим количеством часов дискомфорта во сне

CREATE VIEW IF NOT EXISTS stat_06_worst_sleep_comfort_top AS
SELECT
    rc.complex_id,
    rc.complex,
    rc.building_id,
    rc.building,
    rc.apartment_id,
    rc.apartment_no,
    SUM(rc.is_sleep_discomfort) AS total_sleep_discomfort_hours,
    COUNT(rc.hour_ts) AS total_observed_hours
FROM view_room_comfort_hourly rc
GROUP BY rc.complex_id, rc.complex, rc.building_id, rc.building, rc.apartment_id, rc.apartment_no
HAVING total_observed_hours > 24
ORDER BY total_sleep_discomfort_hours DESC;