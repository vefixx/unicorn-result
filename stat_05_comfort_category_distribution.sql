-- Распределение категорий комфорта по комплексу

CREATE VIEW IF NOT EXISTS stat_05_comfort_category_distribution AS
SELECT
    c.complex_id,
    c.name AS complex,
    rc.comfort_category,
    COUNT(rc.apartment_id) AS apartment_count,
    ROUND(CAST(COUNT(rc.apartment_id) AS REAL) * 100.0 / SUM(COUNT(rc.apartment_id)) OVER(PARTITION BY c.complex_id), 1) AS percentage
FROM complex c
         JOIN building b ON b.complex_id = c.complex_id
         JOIN apartment a ON a.building_id = b.building_id
         LEFT JOIN (
    -- Извлекаем последнюю доступную оценку комфорта для каждой квартиры
    SELECT apartment_id, comfort_category,
           ROW_NUMBER() OVER(PARTITION BY apartment_id ORDER BY hour_ts DESC) as rn
    FROM view_room_comfort_hourly
) rc ON a.apartment_id = rc.apartment_id AND rc.rn = 1
GROUP BY c.complex_id, c.name, rc.comfort_category
ORDER BY c.complex_id, percentage DESC;