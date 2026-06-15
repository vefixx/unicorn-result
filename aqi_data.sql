-- Таблица пороговых значений для расчета IAQI
-- https://atmotube.com/blog/indoor-air-quality-index-iaqi


CREATE TABLE IF NOT EXISTS aqi_data
(
    breakpoint_id  INTEGER PRIMARY KEY,
    pollutant_code TEXT    NOT NULL,
    unit           TEXT    NOT NULL,
    conc_low       REAL    NOT NULL,
    conc_high      REAL,
    iaqi_low       INTEGER NOT NULL,
    iaqi_high      INTEGER NOT NULL,
    category       TEXT    NOT NULL
);

INSERT INTO aqi_data (pollutant_code, unit, conc_low, conc_high, iaqi_low, iaqi_high, category)
VALUES ('co2_ppm', 'ppm', 0, 600, 81, 100, 'good'),
       ('co2_ppm', 'ppm', 600, 1000, 61, 80, 'moderate'),
       ('co2_ppm', 'ppm', 1000, 1500, 41, 60, 'polluted'),
       ('co2_ppm', 'ppm', 1500, 2500, 21, 40, 'very_polluted'),
       ('co2_ppm', 'ppm', 2500, 5000, 0, 20, 'severely_polluted');

INSERT INTO aqi_data (pollutant_code, unit, conc_low, conc_high, iaqi_low, iaqi_high, category)
VALUES ('pm25_ug_m3', 'ug/m3', 0, 12, 81, 100, 'good'),
       ('pm25_ug_m3', 'ug/m3', 12, 35, 61, 80, 'moderate'),
       ('pm25_ug_m3', 'ug/m3', 35, 55, 41, 60, 'polluted'),
       ('pm25_ug_m3', 'ug/m3', 55, 150, 21, 40, 'very_polluted'),
       ('pm25_ug_m3', 'ug/m3', 150, 500, 0, 20, 'severely_polluted');

INSERT INTO aqi_data (pollutant_code, unit, conc_low, conc_high, iaqi_low, iaqi_high, category)
VALUES ('voc_index', 'index', 0, 200, 81, 100, 'good'),
       ('voc_index', 'index', 200, 500, 61, 80, 'moderate'),
       ('voc_index', 'index', 500, 1000, 41, 60, 'polluted'),
       ('voc_index', 'index', 1000, 2000, 21, 40, 'very_polluted'),
       ('voc_index', 'index', 2000, 5000, 0, 20, 'severely_polluted');


INSERT INTO aqi_data (pollutant_code, unit, conc_low, conc_high, iaqi_low, iaqi_high, category)
VALUES ('room_temp_c', 'C', 20, 24, 81, 100, 'good'),
       ('room_temp_c', 'C', 18, 20, 61, 80, 'moderate'),
       ('room_temp_c', 'C', 24, 26, 61, 80, 'moderate'),
       ('room_temp_c', 'C', 16, 18, 41, 60, 'polluted'),
       ('room_temp_c', 'C', 26, 28, 41, 60, 'polluted'),
       ('room_temp_c', 'C', 12, 16, 21, 40, 'very_polluted'),
       ('room_temp_c', 'C', 28, 32, 21, 40, 'very_polluted'),
       ('room_temp_c', 'C', 0, 12, 0, 20, 'severely_polluted'),
       ('room_temp_c', 'C', 32, 50, 0, 20, 'severely_polluted');

INSERT INTO aqi_data (pollutant_code, unit, conc_low, conc_high, iaqi_low, iaqi_high, category)
VALUES ('humidity_pct', '%', 40, 60, 81, 100, 'good'),
       ('humidity_pct', '%', 30, 40, 61, 80, 'moderate'),
       ('humidity_pct', '%', 60, 70, 61, 80, 'moderate'),
       ('humidity_pct', '%', 20, 30, 41, 60, 'polluted'),
       ('humidity_pct', '%', 70, 80, 41, 60, 'polluted'),
       ('humidity_pct', '%', 10, 20, 21, 40, 'very_polluted'),
       ('humidity_pct', '%', 80, 90, 21, 40, 'very_polluted'),
       ('humidity_pct', '%', 0, 10, 0, 20, 'severely_polluted'),
       ('humidity_pct', '%', 90, 100, 0, 20, 'severely_polluted');
